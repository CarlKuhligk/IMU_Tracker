<?php


class Channel
{
    public static $clients;
    public $id;
    public $name;
    public $dataTableName;
    public $online = false;
    public $state = 0; // reserved
    public $subscriberCount = 0;
    private $sender = null;
    private $subscribers = array();

    public function __construct($id, $name)
    {
        $this->id = $id;
        $this->name = $name;
        $this->dataTableName = $this->name . '_' . $this->id;
        echo "Channel " . $this->id . " : Name: " . $this->name . "\n";
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

    public function addSubscriber($resourceId)
    {
        if ($this->isSubscribed($resourceId)) {
            // error cant add resourceId
            return false;
        } else {
            $this->subscribers[$resourceId] = $resourceId;
            $this->subscriberCount++;
            // successfuly added
            return true;
        }
    }

    public function removeSubscriber($resourceId)
    {
        if ($this->isSubscribed($resourceId)) {
            // successfuly removed
            unset($this->subscribers[$resourceId]);
            $this->subscriberCount--;
            return true;
        } else {
            // error resourceId do not exsits
            return false;
        }
    }

    public function isSubscribed($resourceId)
    {
        return array_key_exists($resourceId, $this->subscribers);
    }

    // send local message to all channel subscriber
    public function send($message)
    {
        foreach ($this->subscribers as $subscriber) {
            Channel::$clients[$subscriber->id]->send($message);
        }
    }

    public function isSender($resourceId)
    {
        return ($this->sender == $resourceId ? True : False);
    }
}
