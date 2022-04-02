<?php


class Settings
{
    public $idleTimeout;
    public $batteryWarning;
    public $connectionTimeout;
    public $measurementInterval;
}


class Device
{
    public static $clients;
    public $id;
    public $employee;
    public $loginState = false;
    public $isConnected = false;

    // timeout trigger
    public $lastSeen;
    public $elapsedTime;

    public $settings;

    public $databaseTableName;
    private $streamer = null;
    private $subscriberList = array();

    public function __construct($deviceData)
    {
        $this->id = $deviceData->id;
        $this->employee = $deviceData->employee;
        $this->databaseTableName = 'device_' . $this->id . "_log";
        $this->loginState = $deviceData->loginState;
        $this->lastSeen = $deviceData->lastSeen;
        $this->calculateElapsedTime();
        // settings
        $this->settings = new Settings;
        $this->settings->idleTimeout = $deviceData->idleTimeout;
        $this->settings->batteryWarning = $deviceData->batteryWarning;
        $this->settings->connectionTimeout = $deviceData->connectionTimeout;
        $this->settings->measurementInterval = $deviceData->measurementInterval;
    }

    public function calculateElapsedTime()
    {
        // timeout initial monitoring ##################################################################################################
        $this->lastSeen = new DateTime($this->lastSeen, new DateTimeZone(getenv("TZ")));
        $now = new DateTime(strtotime(time()), new DateTimeZone(getenv("TZ")));
        $this->elapsedTime = $this->lastSeen->diff($now)->s;
    }


    public function connectionLost()
    {
        if (isset($this->streamer)) {
            // successfully removed
            $this->streamer = null;
            $this->isConnected = false;
            return true;
        } else {
            // error streamer is already removed
            return false;
        }
    }

    public function login($resourceId)
    {
        if (isset($this->streamer)) {
            // error streamer is already set
            return false;
        } else {
            $this->streamer = $resourceId;
            $this->isConnected = true;
            $this->loginState = true;
            // successfully assigned
            return true;
        }
    }

    public function logout()
    {
        if (isset($this->streamer)) {
            // successfully removed
            $this->streamer = null;
            $this->isConnected = false;
            $this->loginState = false;
            return true;
        } else {
            // error streamer is already removed
            return false;
        }
    }

    public function isSubscriber($resourceId)
    {
        return array_key_exists($resourceId, $this->subscriberList);
    }

    // send local message to all device subscriber
    public function send($message)
    {
        foreach ($this->subscriberList as $subscriber) {
            #send message only to subscriberList
            if ($subscriber != $this->streamer) {
                Device::$clients[$subscriber]->send($message);
            }
        }
    }

    public function isStreamer($resourceId)
    {
        return ($this->streamer == $resourceId ? True : False);
    }

    // send message to all streamer devices
    public function sendStreamer($message)
    {
        if (isset($this->streamer)) {
            Device::$clients[$this->streamer]->send($message);
            return True;
        } else {
            return False;
        }
    }
}
