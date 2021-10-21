<?php

class Client
{
    public $id;
    public $ip = "";

    public function __construct($rescourdeId)
    {
        $this->id = $rescourdeId;
    }
}
