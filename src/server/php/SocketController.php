<?php

namespace IMUSocketCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;


include_once 'Console.php';
include_once 'DBController.php';
include_once 'Device.php';
include_once 'Response.php';

use DBController;
use Device;

// SendGlobalMessageFlags
define("SGMF_SUBSCRIBER", 1 << 1);
define("SGMF_Streamer", 1 << 2);
define("SGMF_CONNECTION", 1 << 3);
define("SGMF_UNUSED_CONNECTION", 1 << 4);

class SocketController implements MessageComponentInterface
{
    private $clients = array();
    private $devices = array();
    private $Database;

    function __construct()
    {
        $this->Database = new DBController(getenv("MYSQL_HOST"), getenv("MYSQL_USER"), getenv("MYSQL_PASSWORD"), getenv("MYSQL_DATABASE"));
        if ($this->Database->connect() == false) {
            die("Check your database server!\n");
        }

        console_log("Start system:\n");
        console_log("-> Reset online state\n");
        $this->Database->resetDevices();

        console_log("-> Load database:\n");
        $deviceList = $this->Database->loadDevices();
        foreach ($deviceList as $device) {
            $this->devices[$device->id] = new Device($device->id, $device->staffId);
            $device = $this->devices[$device->id];
            console_log("--> Device id: {$device->id} staffId: {$device->staffId} table: '{$device->databaseTableName}'\n");
        }

        Device::$clients = &$this->clients;
    }

    public function onOpen(ConnectionInterface $clientConnection)
    {
        // Store the new connection to send messages to later
        $this->clients[$clientConnection->resourceId] = $clientConnection;
        console_log("New connection! Client id: {$clientConnection->resourceId} source: {$clientConnection->remoteAddress}\n");
    }

    public function onMessage(ConnectionInterface $client, $message)
    {
        $data = json_decode($message);

        // check if the websocketmessage type is set (see websocketcommunicationdiagramm)
        if (isset($data->t)) {
            $this->handleMessage($client, $data);
        } else {
            $client->send($this->response(RP_MISSING_TYPE));
            return;
        }
    }

    public function onClose(ConnectionInterface $clientConnection)
    {
        foreach ($this->devices as $device) {
            if ($device->unsetStreamer()) {
                // streamer successfully removed
                $this->Database->setDeviceOnlineState($device->id, false);
                // send global device update
                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_SUBSCRIBER);
                break;
            } else {
                $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_SUBSCRIBER);
            }
        }
        // The connection is closed, remove it, as we can no longer send it messages
        unset($this->clients[$clientConnection->resourceId]);
        console_log("Client {$clientConnection->resourceId} has disconnected\n");
    }

    public function onError(ConnectionInterface $clientConnection, \Exception $e)
    {
        console_log("Client {$clientConnection->resourceId} An error has occurred: {$e->getMessage()}\n");
        $clientConnection->close();
    }


    public function handleMessage(ConnectionInterface $client, $data)
    {

        // select type
        switch ($data->t) {
                # login
            case "i":
                $this->handleLogin($client, $data);
                break;
                # logout
            case "o":
                $this->handleLogout($client, $data);
                break;
                # subscribe
            case "s":
                $this->handleSubscription($client, $data);
                break;
                # data
            case "d":
                $this->handleNewTrackingData($client, $data);
                break;
            default:
                $client->send($this->response(RP_UNKNOWN_DATA_TYPE));
        }
    }

    private function handleLogin(ConnectionInterface $client, $data)
    {
        if (isset($data->a)) {
            // apikey check
            if ($device = $this->Database->validateApiKey($data->a)) {
                // check double registration
                if ($this->devices[$device->id]->isOnline) {
                    $client->send($this->response(RP_DEVICE_ALREADY_REGISTERED));
                } else {
                    //check subscription
                    if ($this->devices[$device->id]->isSubscriber($client->resourceId)) {
                        $client->send($this->response(RP_SUBSCRIBER_CANT_REGISTER_AS_DEVICE));
                    } else {
                        $this->devices[$device->id]->setStreamer($client->resourceId);
                        $this->Database->setDeviceOnlineState($device->id, true);
                        $client->send($this->response(RP_DEVICE_REGISTERED));
                        // send global update
                        $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_SUBSCRIBER);
                    }
                }
            } else {
                $client->send($this->response(RP_INVALID_API_KEY));
            }
        } else {
            $client->send($this->response(RP_MISSING_API_KEY));
        }
    }


    private function handleLogout(ConnectionInterface $client, $data)
    {
        if (isset($data->p)) {
            $authenticated = false;
            $callingDevice = Null;
            foreach ($this->devices as $device) {
                // check if the streamers resource id has been logged in
                if ($device->isStreamer($client->resourceId)) {
                    $authenticated = true;
                    $callingDevice = $device;
                    break;
                }
            }
            if ($authenticated) {
                // logout
                // check pni
                $employee = $this->Database->validatePin($data->p, $callingDevice);
                if ($employee) {
                    // logout device
                    $this->devices[$device->id]->unsetStreamer($client->resourceId);
                    $this->Database->setDeviceOnlineState($device->id, false);
                    $client->send($this->response(RP_DEVICE_LOGGED_OUT));
                    // send global update
                    $this->sendGlobalMessage($this->getDeviceInfo($device->id), SGMF_SUBSCRIBER);

                    console_log("Client {$callingDevice->id} {$employee->name} logged out.\n");
                } else {
                    // wrong pin
                    $client->send($this->response(RP_DEVICE_LOGOUT_FAILED));
                }
            } else {
                // cant logout
                $client->send($this->response(RP_DEVICE_NOT_REGISTERED));
            }
        }
    }



    private function handleSubscription(ConnectionInterface $client, $data)
    {
        if (isset($data->i)) {
            // device id check
            if ($device = $this->Database->validateChannelId($data->i)) {
                if (isset($data->s)) {
                    // check is streamer
                    if (!$this->devices[$device->id]->isStreamer($client->resourceId)) {
                        // observe or not observe?
                        // !!! UGLY !!!
                        //  |        |
                        // \ /      \ /
                        //  v        v
                        if ($data->s) {
                            // observe
                            if ($this->devices[$device->id]->addSubscriber($client->resourceId)) {
                                $client->send($this->response(RP_SUBSCRIBER_REGISTERED));
                                $this->updateDeviceSubscriberCount($device->id);
                            } else {
                                $client->send($this->response(RP_SUBSCRIBER_ALREADY_REGISTERED));
                            }
                        } else {
                            // not observe
                            if ($this->devices[$device->id]->removeSubscriber($client->resourceId)) {
                                $client->send($this->response(RP_SUBSCRIBER_UNREGISTERED));
                                $this->updateDeviceSubscriberCount($device->id);
                            } else {
                                $client->send($this->response(RP_SUBSCRIBER_NOT_REGISTERED));
                            }
                        }
                        //  ᴧ        ᴧ
                        // / \      / \
                        //  |        |
                    } else {
                        $client->send($this->response(RP_DEVICE_CANT_REGISTER_AS_SUBSCRIBER));
                    }
                } else {
                    $client->send($this->response(RP_SUBSCRIBER_MISSING_REGISTRATION_STATE));
                }
            } else {
                $client->send($this->response(RP_INVALID_DEVICE_ID));
            }
        } else {
            $client->send($this->response(RP_MISSING_DEVICE_ID));
        }
    }


    private function handleNewTrackingData(ConnectionInterface $client, $data)
    {
        $authenticated = false;
        foreach ($this->devices as $device) {
            // check if the streamers resource id has been authenticated
            if ($device->isStreamer($client->resourceId)) {
                $authenticated = true;
                //check limits / events
                //# TO DO #############################################################################################################################
                // write values in database
                $this->Database->writeTrackingData($device->dataTableName, $data, $device->state);
                // send values to all "device/device" subscribers
                $this->devices[$device->id]->send($data);
            }
        }
        if (!$authenticated) {
            $client->send($this->response(RP_DEVICE_NOT_REGISTERED));
        }
    }


    // send to all client is default without flags
    private function sendGlobalMessage($message, $target = 0)
    {
        if ($target & SGMF_Streamer) {
            foreach ($this->devices as $device) {
                $device->sendStreamer($message);
            }
        }

        if ($target & SGMF_SUBSCRIBER) {
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
                    if (!$device->isStreamer($client->resourceId) || !$device->isSubscriber($client->resourceId)) {
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
                'staffId' => $this->devices[$id]->staffId,
                'online' => $this->devices[$id]->isOnline,
                'state' => $this->devices[$id]->state
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

    private function updateDeviceSubscriberCount($id)
    {
        $this->sendGlobalMessage($this->getDeviceInfo($id), SGMF_SUBSCRIBER);
    }
}
