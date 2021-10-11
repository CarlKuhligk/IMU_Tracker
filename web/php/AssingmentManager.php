<?php

use function PHPSTORM_META\type;

include_once 'Channel.php';

class AssingmentManager
{
    // channel id is used as key
    public $channels = array();

    // normal array key
    public $unassignedConnections = array();


    public function addUnassignedConnection($rescourceId)
    {
        array_push($this->unassignedConnections, $rescourceId);
    }


    public function assignConnection($rescourceId, $channel_id, $channel_name, $type)
    {
        if (!isset($this->channels[$channel_id])) {
            $this->channels[$channel_id] = new Channel($channel_id, $channel_name);
        }

        if ($type == "sender") {
            $this->channels[$channel_id]->senderRescourceId = $rescourceId;
        } else if ($type == "subscriber") {
            array_push($this->channels[$channel_id]->reciverRescourceIds, $rescourceId);
        }

        unset($this->unassignedConnections[array_search($rescourceId, $this->unassignedConnections)]);
    }

    public function unassignConnection($rescourceId, $channel_id)
    {
        if ($this->channels[$channel_id]->senderRescourceId === $rescourceId) {
            $this->channels[$channel_id]->senderRescourceId = null;
            $this->addUnassignedConnection($rescourceId);
            return;
        }
        foreach ($this->channels[$channel_id]->reciverRescourceIds as $key => $reciverRescourceId) {
            if ($reciverRescourceId === $rescourceId) {
                unset($this->channels[$channel_id]->reciverRescourceIds[$key]);
                $this->addUnassignedConnection($rescourceId);
            }
        }
    }

    public function removeConnection($rescourceId, $channel_id)
    {
        if (isset($channel_id)) {
            $this->unassignConnection($rescourceId, $channel_id);
        }
        $key = array_search($rescourceId, $this->unassignedConnections);
        unset($this->unassignedConnections[$key]);
    }
}
