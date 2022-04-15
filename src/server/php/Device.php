<?php
include_once 'DBController.php';
include_once 'EventList.php';
include_once 'EventBuilder.php';
include_once 'ResponseMessageBuilder.php';


class EventStates
{
    public bool $connectionTimeoutIsTriggered = false;
    public bool $idlingTimeoutIsTriggered = false;
    public bool $accelerationExceededIsTriggered = false;
    public bool $rotationExceededIsTriggered = false;
    public bool $batteryEmptyIsTriggered = false;
    public bool $batteryWarningIsTriggered = false;
}

class Settings
{
    public int $idleTimeout = 0;
    public int $batteryWarning = 0;
    public int $connectionTimeout = 0;
    public int $measurementInterval = 0;
    public float $accelerationMin = 0;
    public float $accelerationMax = 0;
    public float $rotationMin = 0;
    public float $rotationMax = 0;
    public int $batteryEmpty = 5;

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
    public static $eventList;
    public static $clientList;              // refers to all connected ConnectionInterface objects
    public static DBController $Database;   // refers to DBController

    private EventStates $eventState;
    public $measurements = [];

    public int $id;                     // device id
    public string $employee;            // contains the name of the operating employee
    public bool $isLoggedIn = false;            // indicates the login state
    public Settings $settings;          // contains all editable device settings
    private $timezone;
    public $isObsolete = false;


    public bool $isConnected = false;   // indicates the connection state of the websocket connection
    private string $ipAddress = "";


    private $timeOfLastConnection;    // used to measure the elapsed time after a connection is closed without logout
    private bool $hasIdleDetected = false;      // used to enable idle time monitoring if movement is lower as min limit
    private $idlingStartedTime;     // used to measure the elapsed time till idling is detected

    public string $databaseTableName = "";   // used for database operations
    public $streamerResourceId = null; // equals the ratchat resource id of the websocket client connection if the client registers as streamerResourceId otherwise its empty


    public function __construct($deviceData)
    {
        $this->eventState = new EventStates();
        $this->timezone = new DateTimeZone(getenv("TZ"));
        // initialize object -> copy initial data
        $this->id = $deviceData->id;
        $this->employee = $deviceData->employee;
        $this->databaseTableName = "device_{$this->id}_log";
        $this->isLoggedIn = $deviceData->isLoggedIn;
        $this->timeOfLastConnection = new DateTime($deviceData->lastConnection, $this->timezone);
        $this->settings = new Settings($deviceData->settings);
    }

    public function loadMeasurements()
    {
        // load measurements
        $this->measurements = Device::$Database->loadMeasurements($this);
        return count($this->measurements);
    }


    private function getTimeNow()
    {
        $now = new DateTime();
        $now->setTimezone($this->timezone);
        return $now;
    }

    private function getElapsedTimeInSeconds($timeToCompareWith)
    {
        $now = $this->getTimeNow();
        return $now->getTimestamp() - $timeToCompareWith->getTimestamp();
    }

    public function login($resourceId)
    {
        $this->isConnected = true;
        $this->isLoggedIn = true;
        $this->streamerResourceId = $resourceId;
        $this->ipAddress = Device::$clientList[$this->streamerResourceId]->remoteAddress;


        //#region [events]
        $eventContainer = new SecurityEventContainer();
        array_push($eventContainer->events, new SecurityEvent(E_CONNECTION_LOST, false));
        array_push($eventContainer->events, new SecurityEvent(E_CONNECTION_TIMEOUT, false));

        $eventContainer->timestamp = Device::$Database->insertEvents($this->id, $eventContainer->events);
        $this->addToEventList($eventContainer);
        $this->eventState->connectionTimeoutIsTriggered = false;
        //#endregion

        // update database
        Device::$Database->setDeviceIsConnected($this->id, true);
        Device::$Database->setLoginState($this->id, false);

        return  $eventContainer;
    }

    public function logout()
    {
        $this->isConnected = false;
        $this->isLoggedIn = false;
        $this->streamerResourceId = null;
        $this->ipAddress = "";

        // update database
        Device::$Database->setDeviceIsConnected($this->id, false);
        Device::$Database->setLoginState($this->id, true);
    }

    private function isClientAlive()
    {
        if ($this->isConnected) {
            exec("ping -c 1 " . $this->ipAddress, $output, $result);
            if ($result == 0)
                return true;
            else
                return false;
        }
        return false;
    }

    //#region [events]
    public function connectionClosed()
    {
        if (isset($this->streamerResourceId) || $this->isLoggedIn) {
            // connection closed without logout
            $this->streamerResourceId = null;
            $this->isConnected = false;
            $this->timeOfLastConnection = $this->getTimeNow();
            Device::$Database->setDeviceIsConnected($this->id, false);
            Device::$Database->setLastConnectionTime($this->id, $this->timeOfLastConnection);
            $eventContainer = new SecurityEventContainer();
            array_push($eventContainer->events, new SecurityEvent(E_CONNECTION_LOST, true));

            $eventContainer->timestamp = Device::$Database->insertEvents($this->id, $eventContainer->events);
            $this->addToEventList($eventContainer);

            return $eventContainer;
        } else {
            return null;
            // client successfully closed connection with logout
        }
    }


    public function processTrackingData($data)
    {
        // storage for detected events
        $eventContainer = new SecurityEventContainer();

        // event triggers
        // battery
        if (!$this->eventState->batteryEmptyIsTriggered && $data->b <= $this->settings->batteryEmpty) {
            $this->eventState->batteryEmptyIsTriggered = true;
            array_push($eventContainer->events, new SecurityEvent(E_BATTERY_EMPTY, true));
        } elseif (!$this->eventState->batteryWarningIsTriggered && $data->b <= $this->settings->batteryWarning) {
            $this->eventState->batteryWarningIsTriggered = true;
            array_push($eventContainer->events, new SecurityEvent(E_BATTERY_WARNING, true));
        } elseif ($this->eventState->batteryEmptyIsTriggered && $data->b > $this->settings->batteryEmpty) {
            $this->eventState->batteryEmptyIsTriggered = false;
            array_push($eventContainer->events, new SecurityEvent(E_BATTERY_EMPTY, false));
        } elseif ($this->eventState->batteryWarningIsTriggered && $data->b > $this->settings->batteryWarning) {
            $this->eventState->batteryWarningIsTriggered = false;
            array_push($eventContainer->events, new SecurityEvent(E_BATTERY_WARNING, false));
        }

        // acceleration exceeds limits
        if (!$this->eventState->accelerationExceededIsTriggered && $data->a >= $this->settings->accelerationMax) {
            $this->eventState->accelerationExceededIsTriggered = true;
            array_push($eventContainer->events, new SecurityEvent(E_ACCELERATION_LIMIT_EXCEEDED, true));
        } elseif ($this->eventState->accelerationExceededIsTriggered && $data->a < $this->settings->accelerationMax) {
            $this->eventState->accelerationExceededIsTriggered = false;
            array_push($eventContainer->events, new SecurityEvent(E_ACCELERATION_LIMIT_EXCEEDED, false));
        }

        // rotation exceeds limits
        if (!$this->eventState->rotationExceededIsTriggered && $data->r >= $this->settings->rotationMax) {
            $this->eventState->rotationExceededIsTriggered = true;
            array_push($eventContainer->events, new SecurityEvent(E_ROTATION_LIMIT_EXCEEDED, true));
        } elseif ($this->eventState->rotationExceededIsTriggered && $data->r < $this->settings->rotationMax) {
            $this->eventState->rotationExceededIsTriggered = false;
            array_push($eventContainer->events, new SecurityEvent(E_ROTATION_LIMIT_EXCEEDED, false));
        }

        // detect idling
        if ($this->hasIdleDetected($data->a, $data->r)) {
            $this->hasIdleDetected = true;
            $this->idlingStartedTime = $this->getTimeNow();
        } elseif ($this->eventState->idlingTimeoutIsTriggered) {
            $this->eventState->idlingTimeoutIsTriggered = false;
            array_push($eventContainer->events, new SecurityEvent(E_IDLING, false));
            $this->hasIdleDetected = false;
        }

        Device::$Database->insertEvents($this->id, $eventContainer->events);
        $eventContainer->timestamp = Device::$Database->insertTrackingData($this, $data);
        $this->addToEventList($eventContainer);


        $newMeasurement = (object)[
            't' => $eventContainer->timestamp,
            'a' => $data->a,
            'r' => $data->r,
            'tp' => $data->tp,
            'b' => $data->b
        ];
        array_push($this->measurements, $newMeasurement);
        return $eventContainer;
    }

    public function monitoringTimeouts()
    {
        $eventContainer = new SecurityEventContainer();

        if ($this->isConnected && !$this->isClientAlive()) {
            Device::$clientList[$this->streamerResourceId]->close();
        }

        if ($this->isConnected) {
            if ($this->hasIdleTimeoutDetected())
                array_push($eventContainer->events,  new SecurityEvent(E_IDLING, true));
        } else {
            if ($this->hasConnectionTimeoutDetected())
                array_push($eventContainer->events,  new SecurityEvent(E_CONNECTION_TIMEOUT, true));
        }

        $eventContainer->timestamp = Device::$Database->insertEvents($this->id, $eventContainer->events);
        $this->addToEventList($eventContainer);
        return $eventContainer;
    }

    private function hasIdleDetected($acceleration, $rotation)
    {
        if ($acceleration <= $this->settings->accelerationMin && $rotation <= $this->settings->rotationMin) {
            return true;
        } else {
            return false;
        }
    }

    private function hasIdleTimeoutDetected()
    {
        if ($this->eventState->idlingTimeoutIsTriggered) return false;
        if ($this->hasIdleDetected) {
            $idleTime = $this->getElapsedTimeInSeconds($this->idlingStartedTime);
            if ($idleTime >= $this->settings->idleTimeout) {
                $this->eventState->idlingTimeoutIsTriggered = true;
                return true;
            }
        }
        return false;
    }

    private function hasConnectionTimeoutDetected()
    {
        if ($this->eventState->connectionTimeoutIsTriggered) return false;
        if ($this->isLoggedIn) {
            $timeSinceConnectionLost = $this->getElapsedTimeInSeconds($this->timeOfLastConnection);
            if ($timeSinceConnectionLost >= $this->settings->connectionTimeout) {
                $this->eventState->connectionTimeoutIsTriggered = true;
                return true;
            }
        }
        return false;
    }

    private function addToEventList(SecurityEventContainer $eventContainer)
    {
        if (isset($eventContainer) && count($eventContainer->events) > 0) {
            $eventsToAdd = buildEventList($this->id, $eventContainer);
            foreach ($eventsToAdd as $newEvent) {
                array_push(Device::$eventList, $newEvent);
            }
        }
    }


    //#endregion

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
}
