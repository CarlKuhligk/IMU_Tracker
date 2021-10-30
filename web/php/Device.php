<?php


class Device
{
    public static $clients;
    public $id;
    public $name;
    public $dataTableName;
    public $online = false;
    public $state = 0; // reserved
    public $observerCount = 0;
    # position
    public $alarmLatitude;
    public $alarmLongitude;
    public $lastLatitude;
    public $lastLongitude;

    #battery
    public $battery;

    private $sender = null;
    private $observers = array();

    public function __construct($id, $name)
    {
        $this->id = $id;
        $this->name = $name;
        $this->dataTableName = 'device_' . $this->id;
        echo "Device " . $this->id . " : Name: " . $this->name . "\n";
    }

    public function setSender($resourceId)
    {
        if (isset($this->sender)) {
            // error sender is already set
            return false;
        } else {
            $this->sender = $resourceId;
            $this->online = true;
            // successfuly assigned
            return true;
        }
    }

    public function unsetSender()
    {
        if (isset($this->sender)) {
            // successfuly removed
            $this->sender = null;
            $this->online = false;
            return true;
        } else {
            // error sender is already removed
            return false;
        }
    }

    public function addObserver($resourceId)
    {
        if ($this->isObserver($resourceId)) {
            // error cant add resourceId
            return false;
        } else {
            $this->observers[$resourceId] = $resourceId;
            $this->observerCount++;
            // successfuly added
            return true;
        }
    }

    public function removeObserver($resourceId)
    {
        if ($this->isObserver($resourceId)) {
            // successfuly removed
            unset($this->observers[$resourceId]);
            $this->observerCount--;
            return true;
        } else {
            // error resourceId do not exsits
            return false;
        }
    }

    public function isObserver($resourceId)
    {
        return array_key_exists($resourceId, $this->observers);
    }

    // send local message to all Device observer
    public function send($message)
    {
        foreach ($this->observers as $observer) {
            #send message only to observers
            if ($observer != $this->sender) {
                Device::$clients[$observer]->send($message);
            }
        }
    }

    public function isSender($resourceId)
    {
        return ($this->sender == $resourceId ? True : False);
    }

    public function sendSender($message)
    {
        if (isset($this->sender)) {
            Device::$clients[$this->sender]->send($message);
            return True;
        } else {
            return False;
        }
    }
}
