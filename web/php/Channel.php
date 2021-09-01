<?php

class Channel{
    public $dataTableName;
    public $id;
    public $senderRescourceId;
    public $reciverRescourceIds = array();

    public function __construct($id, $dataTableName){
        $this->id = $id;
        $this->dataTableName = $dataTableName;
    }
}
