<?php

namespace IMUSocketCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

include_once 'DBController.php';
include_once 'DBConfig.php';
include_once 'AssingmentManager.php';

use DBController;
use DBConfig;
use AssingmentManager;


class SocketController extends DBConfig implements MessageComponentInterface
{
    protected $clients;

    private $assingMgr;
    private $db;


    public function __construct()
    {
        $this->clients = [];
        $this->assingMgr = new AssingmentManager();
        $this->db = new DBController();
        if ($this->db->connect($this->servername, $this->username, $this->password, $this->dbname) === false) {
            die("Connection to database faild!");
        }
    }


    # need to be implemented in IMUSocketServer.php
    # server shut down -> set all channels offline!
    #########################################################################################################
    public function __destruct()
    {
        // close all connections!
        foreach ($this->assingMgr->channels as $channel) {
            // close senderconnection
            if (isset($channel->senderRescourceId)) {
                $this->clients[$channel->senderRescourceId]->close();
                $this->db->setChannelOnlineState($channel->id, 0);
            }
            // check all reciver of this channel
            foreach ($channel->reciverRescourceIds as $reciverRescourceId) {
                // close all reciverconnections
                $this->clients[$reciverRescourceId]->send("server shut down");
                $this->clients[$reciverRescourceId]->close();
                $this->assingMgr->removeConnection($reciverRescourceId, $channel->id);
            }
            $this->db->setSubscriberCount($channel->id, count($this->assingMgr->channels[$channel->id]->reciverRescourceIds));
        }
    }
    #########################################################################################################

    public function onOpen(ConnectionInterface $clientConnection)
    {
        // Store the new connection to send messages to later
        $this->clients[$clientConnection->resourceId] = $clientConnection;
        $this->assingMgr->addUnassignedConnection($clientConnection->resourceId);
        // send current state of all channels
        foreach ($this->assingMgr->channels as $channel) {
            $this->clients[$clientConnection->resourceId]->send($this->getChannelInfo($channel->id));
        }
        echo "New connection! ({$clientConnection->resourceId})\n";
    }

    public function onMessage(ConnectionInterface $from, $message)
    {
        // convert string to object
        $data = json_decode($message);

        // break if data is missing
        if (!isset($data->type)) {
            $from->send("error: type is missing\n");
            return;
        }

        // handle incoming data
        switch ($data->type) {
            case "sender":
                // apikey check
                if ($channel = $this->db->validateApiKey($data->value)) {
                    // check double registration
                    if (!$this->db->getChannelOnlineState($channel->id)) {
                        $this->assingMgr->assignConnection($from->resourceId, $channel->id, $channel->name, "sender");
                        $this->db->setChannelOnlineState($channel->id, true);
                        $from->send("sucsessfully authenticated\n");
                        // send global update
                        $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                    } else {
                        $from->send("error: sender is already online\n");
                    }
                } else {
                    $from->send("error: invailid api key\n");
                }
                break;
            case "subscribe":
                // channel id check
                if ($channel = $this->db->validateChannelId($data->channel_id)) {
                    $channelExsits = array_key_exists($channel->id, $this->assingMgr->channels);
                    // check double registration
                    if ($channelExsits) {
                        $reciverRegisterd = in_array($from->resourceId, $this->assingMgr->channels[$channel->id]->reciverRescourceIds, false);
                    } else {
                        $reciverRegisterd = false;
                    }
                    // subscribe or unsubscribe?
                    if ($data->subscribe) {
                        // SUBSCRIBE
                        if (!$reciverRegisterd) {
                            $this->assingMgr->assignConnection($from->resourceId, $channel->id, $channel->name, "subscriber");
                            $from->send("sucsessfully subscribed\n");
                            # code dupication 1
                            $this->db->setSubscriberCount($channel->id, count($this->assingMgr->channels[$channel->id]->reciverRescourceIds));
                            // send global update
                            $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                        } else {
                            $from->send("error: already subscribed\n");
                        }
                    } else {
                        // UNSBSCRIBE
                        if ($reciverRegisterd) {
                            $this->assingMgr->unassignConnection($from->resourceId, $channel->id);
                            $from->send("sucsessfully unsubscribed\n");
                            # code dupication 1
                            $this->db->setSubscriberCount($channel->id, count($this->assingMgr->channels[$channel->id]->reciverRescourceIds));
                            // send global update
                            $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                        } else {
                            $from->send("error: already unsubscribed\n");
                        }
                    }
                } else {
                    $from->send("error: invalid channel id\n");
                }
                break;
            case "data":
                for ($i = 0; $i < 7; $i++) {
                    // check if is empty or not a number
                    if ($data->value[$i] == null || !is_numeric($data->value[$i] + 0)) {
                        $from->send("error: data is missing\n");
                        return;
                    }
                }
                $authenticated = false;
                foreach ($this->assingMgr->channels as $channel) {
                    // check if the senders recource id has been authenticated
                    if ($channel->senderRescourceId === $from->resourceId) {
                        $authenticated = true;
                        // write values in database
                        $this->db->writeSensorData($channel->dataTableName, $data->value);
                        // send values to all "channel/channel" subscribers
                        $this->sendLocalMessage($channel, $message);
                    }
                }
                if (!$authenticated) {
                    $from->send("error: not authenticated\n");
                }
                break;
            default:
                $from->send("error: unknown type\n");
        }
    }

    public function onClose(ConnectionInterface $clientConnection)
    {
        foreach ($this->assingMgr->channels as $channel) {
            if ($channel->senderRescourceId == $clientConnection->resourceId) {
                $this->assingMgr->removeConnection($clientConnection->resourceId, $channel->id);
                $this->db->setChannelOnlineState($channel->id, false);
                // send global event sender/channel disconnected
                $this->sendGlobalMessage($this->getChannelInfo($channel->id));
            }
            foreach ($channel->reciverRescourceIds as $reciverRescourceId) {
                if ($reciverRescourceId == $clientConnection->resourceId) {
                    $this->assingMgr->removeConnection($reciverRescourceId, $channel->id);
                    $this->db->setSubscriberCount($channel->id, count($this->assingMgr->channels[$channel->id]->reciverRescourceIds));
                    // send global event subscriber disconnected
                    $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                }
            }
        }
        foreach ($this->assingMgr->unassignedConnections as $rescourceId) {
            $this->assingMgr->removeConnection($rescourceId, null);
        }
        // The connection is closed, remove it, as we can no longer send it messages
        unset($this->clients[$clientConnection->resourceId]);

        echo "Connection {$clientConnection->resourceId} has disconnected\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e)
    {
        echo "An error has occurred: {$e->getMessage()}\n";

        $conn->close();
    }

    # send messages
    private function sendLocalMessage($channel, $message)
    {
        foreach ($this->assingMgr->channels[$channel->id]->reciverRescourceIds as $reciverRescourceId) {
            $this->clients[$reciverRescourceId]->send($message);
        }
    }

    private function sendGlobalMessage($message)
    {
        foreach ($this->assingMgr->channels as $channel) {
            $this->sendLocalMessage($channel, $message);
        }
        foreach ($this->assingMgr->unassignedConnections as $reciverRescourceId) {
            $this->clients[$reciverRescourceId]->send($message);
        }
    }

    private function getChannelInfo($id)
    {
        $message = (object)[
            'type' => "update",
            'channel' => [
                'id' => $id,
                'name' => $this->assingMgr->channels[$id]->name,
                'online' => isset($this->assingMgr->channels[$id]->senderRescourceId) ? 1 : 0,
                'state' => "comming soon",
                'reciver' => count($this->assingMgr->channels[$id]->reciverRescourceIds)
            ]
        ];
        return json_encode($message);
    }
}
