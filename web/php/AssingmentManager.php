<?php

include_once 'Channel.php';

class AssingmentManager{
    // db table name is used as channel key
    public $channels = array();

    public function addSenderRescourceId($rescourceId, $id, $dataTableName){
        if(!isset($this->channels[$id])){
            $this->channels[$id] = new Channel($id, $dataTableName);
        }
        $this->channels[$id]->senderRescourceId = $rescourceId;
    }

    public function addReciverRescourceId($rescourceId, $id, $dataTableName){
        if(!isset($this->channels[$id])){
           $this->channels[$id] = new Channel($id, $dataTableName);
        }
        array_push($this->channels[$id]->reciverRescourceIds, $rescourceId);
    }

    public function removeSenderRescourceId($rescourceId, $id){
        //if the channel exits
        if(isset($this->channels[$id])){
            // if the senderRescourceId exists
            if(isset($this->channels[$id]->senderRescourceId)){
                // remove from channel
                $this->channels[$id]->senderRescourceId = null;
            }
        }
    }

    public function removeReciverRescourceId($rescourceId, $id){
        //if the channel exits
        if(isset($this->channels[$id])){
            // if the reciverRescourceIds exists
            if(in_array($rescourceId, $this->channels[$id]->reciverRescourceIds)){
                // remove from channel
                unset($this->channels[$id]->reciverRescourceIds[array_search($rescourceId, $this->channels[$id]->reciverRescourceIds)]);
            }
        }
    }

}
?>