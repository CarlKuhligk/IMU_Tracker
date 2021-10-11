<?php

class Channel
{
    public $name;
    public $dataTableName;
    public $id;
    public $senderRescourceId;
    public $reciverRescourceIds = array();

    public function __construct($id, $name)
    {
        $this->id = $id;
        $this->name = $name;
        $this->dataTableName = $this->name . '_' . $this->id;
    }
}
