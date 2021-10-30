<?php

namespace IMUSocketCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

include_once 'DBController.php';
include_once 'Device.php';
include_once 'DBConfig.php';

use DBConfig;
use DBController;
use Device;

class SocketController implements MessageComponentInterface
{
    private $clients = array();
    private $devices = array();
    private $db;

    // global message tagets
    static $Observer = 1 << 1;
    static $Sender = 1 << 2;
    static $Connection = 1 << 3;
    static $UnusedConnection = 1 << 4;

    function __construct()
    {
        $this->db = new DBController(DBConfig::$servername, DBConfig::$username, DBConfig::$password, DBConfig::$dbname);
        if ($this->db->connect() === false) {
            die("Connection to database faild!");
        }
        $this->db->resetDevices();
        // load all devices
        $deviceList = $this->db->loadDevices();
        foreach ($deviceList as $device) {
            $this->devices[$device->id] = new Device($device->id, $device->name);
        }
        // set static reference in class Device
        Device::$clients = &$this->clients;
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
                    if ($device = $this->db->validateApiKey($data->apikey)) {
                        // check double registration
                        if (!$this->devices[$device->id]->online) {
                            //check subscription
                            if (!$this->devices[$device->id]->isObserver($from->resourceId)) {
                                $this->devices[$device->id]->setSender($from->resourceId);
                                $this->db->setDeviceOnlineState($device->id, true);
                                $from->send($this->response(10)); // successfuly registered as sender
                                // send global update
                                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SocketController::$Observer);
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
                if (isset($data->device_id)) {
                    // device id check
                    if ($device = $this->db->validateChannelId($data->device_id)) {
                        if (isset($data->subscribe)) {
                            // check is sender
                            if (!$this->devices[$device->id]->isSender($from->resourceId)) {
                                // subscribe or unsubscribe?
                                // !!! UGLY !!!
                                //  |        |
                                // \ /      \ /
                                //  v        v
                                if ($data->subscribe) {
                                    // SUBSCRIBE
                                    if ($this->devices[$device->id]->addObserver($from->resourceId)) {
                                        $from->send($this->response(11)); // sucsessfully subscribed
                                        $this->updateDeviceObserverCount($device->id);
                                    } else {
                                        $from->send($this->response(24)); // error: already subscribed
                                    }
                                } else {
                                    // UNSBSCRIBE
                                    if ($this->devices[$device->id]->removeObserver($from->resourceId)) {
                                        $from->send($this->response(12)); // successfuly unsubscribed from device
                                        $this->updateDeviceObserverCount($device->id);
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
                        $from->send($this->response(23)); // error: invalid device id
                    }
                } else {
                    $from->send($this->response(26)); // error: missing device id
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
                foreach ($this->devices as $device) {
                    // check if the senders recource id has been authenticated
                    if ($device->isSender($from->resourceId)) {
                        $authenticated = true;
                        // write values in database
                        $this->db->writeDeviceData($device->dataTableName, $data->value);
                        // send values to all "device/device" subscribers
                        $this->devices[$device->id]->send($data->value);
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
        foreach ($this->devices as $device) {
            if ($device->unsetSender()) {
                // sender successfuly removed
                $this->db->setDeviceOnlineState($device->id, false);
                // send global device update
                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SocketController::$Observer);
                break;
            } elseif ($device->removeObserver($clientConnection->resourceId)) {
                // subscriber successfuly removed
                $this->db->setObserverCount($device->id, $this->devices[$device->id]->observerCount);
                // send global device update
                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SocketController::$Observer);
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

    private function sendGlobalMessage($message, $target)
    {
        if ($target & SocketController::$Sender) {
            foreach ($this->devices as $device) {
                $device->sendSender($message);
            }
        }

        if ($target & SocketController::$Observer) {
            foreach ($this->devices as $device) {
                $device->send($message);
            }
        }

        if ($target & SocketController::$Connection) {
            foreach ($this->clients as $client) {
                $client->send($message);
            }
        }

        if ($target & SocketController::$UnusedConnection) {
            foreach ($this->clients as $client) {
                foreach ($this->devices as $device) {
                    if (!$device->isSender($client->resourceId) || !$device->isObserver($client->resourceId)) {
                        $client->send($message);
                    }
                }
            }
        }
    }

    private function getDeviceInfo($id)
    {
        $message = (object)[
            'type' => "update",
            'device' => [
                'id' => $id,
                'name' => $this->devices[$id]->name,
                'online' => $this->devices[$id]->online,
                'state' => $this->devices[$id]->state,
                'reciver' => $this->devices[$id]->observerCount
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

    private function updateDeviceObserverCount($id)
    {
        $this->db->setObserverCount($id, $this->devices[$id]->observerCount);
        $this->sendGlobalMessage($this->getDeviceInfo($id), SocketController::$Observer);
    }
}
