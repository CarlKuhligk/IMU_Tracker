<?php
class Device
{
    public static $clients;
    public $id;
    public $staffId;
    public $databaseTableName;
    public $isOnline = false;
    public $state = 0; // reserved
    public Settings $settings;

    #battery
    public $battery;

    private $streamer = null;
    private $subscriberList = array();

    public function __construct($id, $staffId)
    {
        $this->id = $id;
        $this->staffId = $staffId;
        $this->databaseTableName = 'device_' . $this->id . "_log";
    }

    public function setStreamer($resourceId)
    {
        if (isset($this->streamer)) {
            // error streamer is already set
            return false;
        } else {
            $this->streamer = $resourceId;
            $this->isOnline = true;
            // successfully assigned
            return true;
        }
    }

    public function unsetStreamer()
    {
        if (isset($this->streamer)) {
            // successfully removed
            $this->streamer = null;
            $this->isOnline = false;
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

    // send local message to all Device subscriber
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

class Settings
{
    public $accMax;
    public $accMin;
    public $gyrMax;
    public $gyrMin;
    public $idleTime;
    public $batteryWarning;
    public $timeout;
    public $senseFreq;
}
