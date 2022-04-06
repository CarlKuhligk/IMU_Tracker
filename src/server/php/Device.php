<?php
include_once 'DBController.php';
include_once 'EventList.php';

class EventStates
{
    public bool $connectionTimeoutIsTriggered = false;
}

class Settings
{
    public $idleTimeout = 0;
    public $batteryWarning = 0;
    public $connectionTimeout = 0;
    public $measurementInterval = 0;
    public $accelerationMin = 0;
    public $accelerationMax = 0;
    public $rotationMin = 0;
    public $rotationMax = 0;

    public function __construct($settings)
    {
        $this->idleTimeout = $settings->idleTimeout;
        $this->batteryWarning = $settings->batteryWarning;
        $this->connectionTimeout = $settings->connectionTimeout;
        $this->measurementInterval = $settings->measurementInterval;
        $this->accelerationMin = $settings->accelerationMin;
        $this->accelerationMax = $settings->accelerationMax;
        $this->rotationMin = $settings->rotationMin;
        $this->rotationMax = $settings->rotationMax;
    }
}


class Device
{
    public static $clientList;              // refers to all connected ConnectionInterface objects
    public static DBController $Database;   // refers to DBController

    private EventStates $eventState;

    public int $id;                     // device id
    public string $employee;            // contains the name of the operating employee
    public bool $isLoggedIn;            // indicates the login state
    private Settings $settings;                  // contains all editable device settings
    private $timezone;


    public bool $isConnected = false;   // indicates the connection state of the websocket connection

    private $lastConnection;    // used to measure the elapsed time after a connection is closed without logout
    private $idleDetected;      // used to enable idle time monitoring if movement is lower as min limit
    private $idlingStarted;     // used to measure the elapsed time till idling is detected


    public string $databaseTableName;   // used for database operations
    private $streamerResourceId = null; // equals the ratchat resource id of the websocket client connection if the client registers as streamerResourceId otherwise its empty


    public function __construct($deviceData)
    {
        $this->eventState = new EventStates();
        $this->timezone = getenv("TZ");
        // initialize object -> copy initial data
        $this->id = $deviceData->id;
        $this->employee = $deviceData->employee;
        $this->databaseTableName = "device_{$this->id}_log";
        $this->isLoggedIn = $deviceData->isLoggedIn;
        $this->lastConnection = new DateTime($deviceData->lastConnection, new DateTimeZone($this->timezone));
        $this->settings = new Settings($deviceData->settings);
    }

    private function getTimeNow()
    {
        return new DateTime(strtotime(time()), new DateTimeZone($this->timezone));
    }

    private function getElapsedTimeInSeconds($timeToCompareWith)
    {
        $now = $this->getTimeNow();
        return $timeToCompareWith->diff($now)->s;
    }

    public function login($resourceId)
    {
        $this->streamerResourceId = $resourceId;
        $this->isConnected = true;
        $this->isLoggedIn = true;

        //#region [keepInMind]
        // event connected##############################################
        //#endregion

        // update database
        Device::$Database->setDeviceIsConnected($this->id, true);
        Device::$Database->setLoginState($this->id, false);
    }

    public function logout()
    {
        $this->streamerResourceId = null;
        $this->isConnected = false;
        $this->isLoggedIn = false;

        // update database
        Device::$Database->setDeviceIsConnected($this->id, false);
        Device::$Database->setLoginState($this->id, true);
    }


    public function connectionClosed()
    {
        if (isset($this->streamerResourceId) || $this->isLoggedIn) {
            // connection closed without logout
            $this->streamerResourceId = null;
            $this->isConnected = false;
            $this->lastConnection = $this->getTimeNow();

            Device::$Database->setDeviceIsConnected($this->id, false);

            //#region [keepInMind]
            return E_CONNECTION_LOST;
            //#endregion

        } else {
            return false;
            // client successfully closed connection with logout
        }
    }

    public function processTrackingData($data)
    {
        // detected events
        $eventList = array();

        // triggers
        // battery
        if ($data->b <= $this->settings->batteryEmpty)
            array_push($eventList, E_BATTERY_EMPTY);
        elseif ($data->b <= $this->settings->batteryWarning)
            array_push($eventList, E_BATTERY_LOW);

        // acceleration exceeds limits
        if ($data->a >= $this->settings->accelerationMax)
            array_push($eventList, E_ACCELERATION_LIMIT_EXCEEDED);

        // rotation exceeds limits
        if ($data->r >= $this->settings->rotationMax)
            array_push($eventList, E_ROTATION_LIMIT_EXCEEDED);

        // monitor idling
        if ($data->a <= $this->settings->accelerationMin && $data->r <= $this->settings->rotationMin) {
            $this->idleDetected = true;
            $this->idlingStarted = $this->getTimeNow();
        } else {
            $this->idleDetected = false;
        }

        Device::$Database->writeTrackingData($this->dataTableName, $data);
        // send values to all "device" subscriber
        $this->send($data);

        return $eventList;
    }

    public function monitoringTimeouts()
    {
        $eventList = array();

        if ($this->isConnected) {
            // check if idle time is exceeded
            if ($this->idleDetected) {
                $idleTime = $this->getElapsedTimeInSeconds($this->idlingStarted);
                if ($idleTime >= $this->settings->idleTimeout)
                    array_push($eventList, E_IDLE);
            }
        } else {
            // connection timeout
            if (!$this->eventState->connectionTimeoutIsTriggered && $this->isLoggedIn) {
                $time = $this->getElapsedTimeInSeconds($this->lastConnection);
                if ($time >= $this->settings->connectionTimeout) {
                    $this->connectionTimeoutIsTriggered = true;
                    array_push($eventList, E_CONNECTION_TIMEOUT);
                }
            }
        }
    }

    public function isSubscriber($resourceId)
    {
        return array_key_exists($resourceId, $this->subscriberList);
    }

    // send local message to all subscriber
    public function send($message)
    {
        if (isset($this->subscriberList))
            foreach ($this->subscriberList as $subscriber) {
                #send message only to subscriberList
                if ($subscriber != $this->streamerResourceId) {
                    Device::$clientList[$subscriber]->send($message);
                }
            }
    }

    public function isStreamer($resourceId)
    {
        return ($this->streamerResourceId == $resourceId ? True : False);
    }

    // send message to the streaming device
    public function sendToStreamingDevice($message)
    {
        Device::$clientList[$this->streamerResourceId]->send($message);
    }

    public function updateSettings($newSettings)
    {
        Device::$Database->updateDeviceSettings($this->id, $newSettings);
        $this->settings->idleTimeout = $newSettings->it;
        $this->settings->batteryWarning = $newSettings->b;
        $this->settings->connectionTimeout = $newSettings->c;
        $this->settings->measurementInterval = $newSettings->m;
        $this->settings->accelerationMin = $newSettings->ai;
        $this->settings->accelerationMax = $newSettings->a;
        $this->settings->rotationMin = $newSettings->ri;
        $this->settings->rotationMax = $newSettings->r;
    }

    public function sendSettings()
    {
        $settingsMessage = (object)[
            't' => "s",
            'it' => "{$this->settings->idleTimeout}",
            'b' => "{$this->settings->batteryWarning}",
            'c' => "{$this->settings->connectionTimeout}",
            'm' => "{$this->settings->measurementInterval}",
            'ai' => "{$this->settings->accelerationMax}",
            'a' => "{$this->settings->accelerationMin}",
            'ri' => "{$this->settings->rotationMin}",
            'r' => "{$this->settings->rotationMax}"
        ];
        $settingsMessage = json_encode($settingsMessage);
        $this->sendToStreamingDevice($settingsMessage);
    }

    private function sendEvent($eventId)
    {
    }
}
