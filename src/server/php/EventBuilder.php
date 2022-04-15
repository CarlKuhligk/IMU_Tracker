<?php
include_once 'Console.php';

class SecurityEvent
{
    public int $id = 0;
    public bool $isTriggered = false;

    // initiate database connection with given parameters
    function __construct($id, $isTriggered)
    {
        $this->id = $id;
        $this->isTriggered = $isTriggered;
    }
}

class SecurityEventContainer
{
    public string $timestamp = "";
    public $events = array();

    // initiate database connection with given parameters
    function __construct($timestamp = "", $events = array())
    {
        $this->timestamp = $timestamp;
        $this->events = $events;
    }
}
