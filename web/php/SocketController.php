<?php

namespace IMUSocketCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

include_once 'DBController.php';
include_once 'Device.php';
include_once 'DBConfig.php';
include_once 'Response.php';

use DBConfig;
use DBController;
use Device;

// SendGlobalMessageFlags
define("SGMF_OBSERVER", 1 << 1);
define("SGMF_SENDER", 1 << 2);
define("SGMF_CONNECTION", 1 << 3);
define("SGMF_UNUSED_CONNECTION", 1 << 4);

class SocketController implements MessageComponentInterface
{
    private $clients = array();
    private $devices = array();
    private $Database;

    function __construct()
    {
        $this->Database = new DBController(DBConfig::$servername, DBConfig::$username, DBConfig::$password, DBConfig::$dbname);
        if ($this->Database->connect() === false) {
            die("Connection to database faild!");
        }
        $this->Database->resetDevices();
        // load all devices
        $deviceList = $this->Database->loadDevices();
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
            $from->send($this->response(RP_MISSING_TYPE));
            return;
        }

        // handle incoming data
        switch ($data->type) {
            case "login":
                if (isset($data->apikey)) {
                    // apikey check
                    if ($device = $this->Database->validateApiKey($data->apikey)) {
                        // check double registration
                        if (!$this->devices[$device->id]->online) {
                            //check subscription
                            if (!$this->devices[$device->id]->isObserver($from->resourceId)) {
                                $this->devices[$device->id]->setSender($from->resourceId);
                                $this->Database->setDeviceOnlineState($device->id, true);
                                $from->send($this->response(RP_DEVICE_REGISTERED));
                                // send global update
                                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_OBSERVER);
                            } else {
                                $from->send($this->response(RP_OBSERVER_CANT_REGISTER_AS_DEVICE));
                            }
                        } else {
                            $from->send($this->response(RP_DEVICE_ALREADY_REGISTERED));
                        }
                    } else {
                        $from->send($this->response(RP_INVALID_API_KEY));
                    }
                } else {
                    $from->send($this->response(RP_MISSING_API_KEY));
                }
                break;
            case "logout":
                if (isset($data->pin)) {
                    $authenticated = false;
                    $callingDevice = NULL;
                    foreach ($this->devices as $device) {
                        // check if the senders recource id has been logedin
                        if ($device->isSender($from->resourceId)) {
                            $authenticated = true;
                            $callingDevice = $device;
                            break;
                        }
                    }
                    if ($authenticated) {
                        // logout
                        // check pni
                        $employee = $this->Database->validatePin($data->pin, $callingDevice);
                        if ($employee) {
                            // logout device
                            $this->devices[$device->id]->unsetSender($from->resourceId);
                            $this->Database->setDeviceOnlineState($device->id, false);
                            $from->send($this->response(RP_DEVICE_LOGGED_OUT));
                            // send global update
                            $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_OBSERVER);

                            echo "Device: " . $callingDevice->id . " logged out from: " . $employee->name;
                        } else {
                            // wrong pin
                            $from->send($this->response(RP_DEVICE_LOGOUT_FAILED));
                        }
                    } else {
                        // cant logout
                        $from->send($this->response(RP_DEVICE_NOT_REGISTERED));
                    }
                }
                break;
            case "observe":
                if (isset($data->device_id)) {
                    // device id check
                    if ($device = $this->Database->validateChannelId($data->device_id)) {
                        if (isset($data->state)) {
                            // check is sender
                            if (!$this->devices[$device->id]->isSender($from->resourceId)) {
                                // observe or not observe?
                                // !!! UGLY !!!
                                //  |        |
                                // \ /      \ /
                                //  v        v
                                if ($data->state) {
                                    // observe
                                    if ($this->devices[$device->id]->addObserver($from->resourceId)) {
                                        $from->send($this->response(RP_OBSERVER_REGISTERED));
                                        $this->updateDeviceObserverCount($device->id);
                                    } else {
                                        $from->send($this->response(RP_OBSERVER_ALREADY_REGISTERED));
                                    }
                                } else {
                                    // not observe
                                    if ($this->devices[$device->id]->removeObserver($from->resourceId)) {
                                        $from->send($this->response(RP_OBSERVER_UNREGISTERED));
                                        $this->updateDeviceObserverCount($device->id);
                                    } else {
                                        $from->send($this->response(RP_OBSERVER_NOT_REGISTERED));
                                    }
                                }
                                //  ᴧ        ᴧ
                                // / \      / \
                                //  |        |
                            } else {
                                $from->send($this->response(RP_DEVICE_CANT_REGISTER_AS_OBSERVER));
                            }
                        } else {
                            $from->send($this->response(RP_OBSERVER_MISSING_REGESTRATION_STATE));
                        }
                    } else {
                        $from->send($this->response(RP_INVALID_DEVICE_ID));
                    }
                } else {
                    $from->send($this->response(RP_MISSING_DEVICE_ID));
                }
                break;
            case "data":
                for ($i = 0; $i < 8; $i++) {
                    // check if is empty or not a number
                    if ($data->value[$i] == null || !is_numeric($data->value[$i] + 0)) {
                        $from->send($this->response(RP_MISSING_DATA));
                        return;
                    }
                }
                $authenticated = false;
                foreach ($this->devices as $device) {
                    // check if the senders recource id has been authenticated
                    if ($device->isSender($from->resourceId)) {
                        $authenticated = true;
                        // write values in database
                        $this->Database->writeDeviceData($device->dataTableName, $data->value);
                        // send values to all "device/device" subscribers
                        $this->devices[$device->id]->send($data->value);
                    }
                }
                if (!$authenticated) {
                    $from->send($this->response(RP_DEVICE_NOT_REGISTERED));
                }
                break;
            default:
                $from->send($this->response(RP_UNKNOWN_DATA_TYPE));
        }
    }

    public function onClose(ConnectionInterface $clientConnection)
    {
        foreach ($this->devices as $device) {
            if ($device->unsetSender()) {
                // sender successfuly removed
                $this->Database->setDeviceOnlineState($device->id, false);
                // send global device update
                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_OBSERVER);
                break;
            } elseif ($device->removeObserver($clientConnection->resourceId)) {
                // subscriber successfuly removed
                $this->Database->setObserverCount($device->id, $this->devices[$device->id]->observerCount);
                // send global device update
                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_OBSERVER);
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

    // send to all client is default without flags
    private function sendGlobalMessage($message, $target = 0)
    {
        if ($target & SGMF_SENDER) {
            foreach ($this->devices as $device) {
                $device->sendSender($message);
            }
        }

        if ($target & SGMF_OBSERVER) {
            foreach ($this->devices as $device) {
                $device->send($message);
            }
        }

        // send to all client is default
        if (($target & SGMF_CONNECTION) || $target = 0) {
            foreach ($this->clients as $client) {
                $client->send($message);
            }
        }

        if ($target & SGMF_UNUSED_CONNECTION) {
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
                'observer' => $this->devices[$id]->observerCount
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
        $this->Database->setObserverCount($id, $this->devices[$id]->observerCount);
        $this->sendGlobalMessage($this->getDeviceInfo($id), SGMF_OBSERVER);
    }
}
