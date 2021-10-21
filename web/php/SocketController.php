<?php

namespace IMUSocketCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

include_once 'DBController.php';
include_once 'Channel.php';
include_once 'DBConfig.php';

use DBConfig;
use DBController;
use Channel;

class SocketController implements MessageComponentInterface
{
    private $clients = array();
    private $channels = array();
    private $db;

    function __construct()
    {
        $this->db = new DBController(DBConfig::$servername, DBConfig::$username, DBConfig::$password, DBConfig::$dbname);
        if ($this->db->connect() === false) {
            die("Connection to database faild!");
        }
        $this->db->resetChannels();
        // load all channels
        $channelInformation = $this->db->loadChannels();
        foreach ($channelInformation as $channel) {
            $this->channels[$channel->id] = new Channel($channel->id, $channel->name);
        }
        // set static reference in class Channel
        Channel::$clients = &$this->clients;
    }

    public function onOpen(ConnectionInterface $clientConnection)
    {
        // Store the new connection to send messages to later
        $this->clients[$clientConnection->resourceId] = $clientConnection;
        echo "New connection! ({$clientConnection->resourceId})\n";
    }

    public function onMessage(ConnectionInterface $from, $message)
    {
        // convert string to object
        $data = json_decode($message);

        // break if datatype is missing
        if (!isset($data->type)) {
            $from->send($this->response(30)); // error: type missing
            return;
        }

        // handle incoming data
        switch ($data->type) {
            case "sender":
                if (isset($data->apikey)) {
                    // apikey check
                    if ($channel = $this->db->validateApiKey($data->apikey)) {
                        // check double registration
                        if (!$this->channels[$channel->id]->online) {
                            //check subscription
                            if (!$this->channels[$channel->id]->isSubscribed($from->resourceId)) {
                                $this->channels[$channel->id]->setSender($from->resourceId);
                                $this->db->setChannelOnlineState($channel->id, true);
                                $from->send($this->response(10)); // successfuly registered as sender
                                // send global update
                                $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                            } else {
                                $from->send($this->response(28)); // error: subscriber, cant be a sender at same time
                            }
                        } else {
                            $from->send($this->response(21)); // error: already redisterd as sender
                        }
                    } else {
                        $from->send($this->response(20)); // invailid api key
                    }
                } else {
                    $from->send($this->response(19)); // missing apikey
                }
                break;
            case "subscribe":
                if (isset($data->channel_id)) {
                    // channel id check
                    if ($channel = $this->db->validateChannelId($data->channel_id)) {
                        if (isset($data->subscribe)) {
                            // check is sender
                            if (!$this->channels[$channel->id]->isSender($from->resourceId)) {
                                // subscribe or unsubscribe?
                                // !!! UGLY !!!
                                //  |        |
                                // \ /      \ /
                                //  v        v
                                if ($data->subscribe) {
                                    // SUBSCRIBE
                                    if ($this->channels[$channel->id]->addSubscriber($from->resourceId)) {
                                        $from->send($this->response(11)); // sucsessfully subscribed
                                        $this->updateChannelSubscriberCount($channel->id);
                                    } else {
                                        $from->send($this->response(24)); // error: already subscribed
                                    }
                                } else {
                                    // UNSBSCRIBE
                                    if ($this->channels[$channel->id]->removeSubscriber($from->resourceId)) {
                                        $from->send($this->response(12)); // successfuly unsubscribed from channel
                                        $this->updateChannelSubscriberCount($channel->id);
                                    } else {
                                        $from->send($this->response(25)); // error: not subscribed
                                    }
                                }
                                //  ᴧ        ᴧ
                                // / \      / \
                                //  |        |
                            } else {
                                $from->send($this->response(29)); // error : sender, cant be a subscriber at same
                            }
                        } else {
                            $from->send($this->response(27)); // error: missing subscription data
                        }
                    } else {
                        $from->send($this->response(23)); // error: invalid channel id
                    }
                } else {
                    $from->send($this->response(26)); // error: missing channel id
                }
                break;
            case "data":
                for ($i = 0; $i < 7; $i++) {
                    // check if is empty or not a number
                    if ($data->value[$i] == null || !is_numeric($data->value[$i] + 0)) {
                        $from->send($this->response(31)); // error: data missing
                        return;
                    }
                }
                $authenticated = false;
                foreach ($this->channels as $channel) {
                    // check if the senders recource id has been authenticated
                    if ($channel->sender === $from->resourceId) {
                        $authenticated = true;
                        // write values in database
                        $this->db->writeSensorData($channel->dataTableName, $data->value);
                        // send values to all "channel/channel" subscribers
                        $this->channels[$channel->id]->send($data->value);
                    }
                }
                if (!$authenticated) {
                    $from->send($this->response(22)); // error: not authenticated as sender
                }
                break;
            default:
                $from->send($this->response(32)); // error: unknown datatype
        }
    }

    public function onClose(ConnectionInterface $clientConnection)
    {
        foreach ($this->channels as $channel) {
            if ($channel->unsetSender()) {
                // sender successfuly removed
                $this->db->setChannelOnlineState($channel->id, false);
                // send global channel update
                $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                break;
            } elseif ($channel->removeSubscriber($clientConnection->resourceId)) {
                // subscriber successfuly removed
                $this->db->setSubscriberCount($channel->id, $this->channels[$channel->id]->subscriberCount);
                // send global channel update
                $this->sendGlobalMessage($this->getChannelInfo($channel->id));
                break;
            }
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


    private function sendGlobalMessage($message)
    {
        foreach ($this->clients as $client) {
            $client->send($message);
        }
    }

    private function getChannelInfo($id)
    {
        $message = (object)[
            'type' => "update",
            'channel' => [
                'id' => $id,
                'name' => $this->channels[$id]->name,
                'online' => $this->channels[$id]->online,
                'state' => $this->channels[$id]->state,
                'reciver' => $this->channels[$id]->subscriberCount
            ]
        ];
        return json_encode($message);
    }

    private function response($responseId)
    {
        $response = (object)[
            'type' => "response",
            'id' => "{$responseId}"
        ];
        return json_encode($response);
    }

    private function updateChannelSubscriberCount($id)
    {
        $this->db->setSubscriberCount($id, $this->channels[$id]->subscriberCount);
        $this->sendGlobalMessage($this->getChannelInfo($id));
    }
}
