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

// MessageFlags
define("MF_SUBSCRIBER", 1 << 1);
define("MF_Streamer", 1 << 2);
define("MF_CONNECTION", 1 << 3);
define("MF_UNUSED_CONNECTION", 1 << 4);

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

        consoleLog("Start system:");
        consoleLog("-> Reset online state");
        $this->Database->resetDevicesIsConnected();

        $this->updateDevices();

        Device::$clients = &$this->clients;
    }

    public function onOpen(ConnectionInterface $client)
    {
        // Store the new connection to send messages to later
        $this->clients[$client->resourceId] = $client;
        consoleLog("New connection! Client id: {$client->resourceId} source: {$client->remoteAddress}");
    }

    public function onMessage(ConnectionInterface $client, $message)
    {
        $data = json_decode($message);

        // check if the websocketmessage type is set (see websocketcommunicationdiagramm)
        if (isset($data->t)) {
            $this->handleMessage($client, $data);
        } else {
            $client->send($this->createResponse(R_MISSING_TYPE));
            return;
        }
    }

    public function onClose(ConnectionInterface $client)
    {
        if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
            $device = $this->devices[$requestingDeviceId];
            $device->connectionLost();
            $this->Database->setDeviceIsConnected($device->id, false);
            // send global device update
            $this->sendGlobalMessage($this->getDeviceInfo($device->id), MF_SUBSCRIBER);
            consoleLog("Device {$requestingDeviceId} : {$this->devices[$requestingDeviceId]->employee} lost connection.");
        } else {
            consoleLog("Client {$client->resourceId} has disconnected");
        }
        // The connection is closed, remove it, as we can no longer send it messages
        unset($this->clients[$client->resourceId]);
    }

    public function onError(ConnectionInterface $client, \Exception $e)
    {
        consoleLog("Client {$client->resourceId} An error has occurred: {$e->getMessage()}");
        $client->close();
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
                $client->send($this->createResponse(R_UNKNOWN_DATA_TYPE));
        }
    }

    private function handleLogin(ConnectionInterface $client, $data)
    {
        if (isset($data->a)) {
            // check if key is valid
            if ($requestingDeviceId = $this->Database->validateKey($data->a)) {
                // check if device is loaded otherwise reload devices and proceed
                if (!array_key_exists($requestingDeviceId, $this->devices))
                    $this->updateDevices();
                // check if device is already registered
                if ($this->devices[$requestingDeviceId]->isConnected) {
                    $client->send($this->createResponse(R_DEVICE_ALREADY_REGISTERED));
                } else {
                    // check if device has subscribed to it self (this is not allowed)
                    if ($this->devices[$requestingDeviceId]->isSubscriber($client->resourceId)) {
                        $client->send($this->createResponse(R_SUBSCRIBER_CANT_REGISTER_AS_DEVICE));
                    } else {
                        $this->devices[$requestingDeviceId]->login($client->resourceId);
                        $this->Database->setDeviceIsConnected($requestingDeviceId, true);
                        $this->Database->setLoginState($requestingDeviceId, false);
                        $client->send($this->createResponse(R_DEVICE_REGISTERED));
                        // send global update #######################################################################################################################################
                        $this->sendGlobalMessage($this->getDeviceInfo($requestingDeviceId), MF_SUBSCRIBER);

                        consoleLog("Device {$requestingDeviceId} : {$this->devices[$requestingDeviceId]->employee} logged in.");
                    }
                }
            } else {
                $client->send($this->createResponse(R_INVALID_API_KEY));
            }
        } else {
            $client->send($this->createResponse(R_MISSING_API_KEY));
        }
    }


    private function handleLogout(ConnectionInterface $client, $data)
    {
        if (isset($data->p)) {
            if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
                // logout
                // check pin
                $employee = $this->Database->validatePin($data->p, $this->devices[$requestingDeviceId]);
                if ($employee) {
                    // logout device
                    $this->devices[$requestingDeviceId]->logout();
                    $this->Database->setDeviceIsConnected($requestingDeviceId, false);
                    $this->Database->setLoginState($requestingDeviceId, true);
                    $client->send($this->createResponse(R_DEVICE_LOGGED_OUT));
                    // send global update
                    $this->sendGlobalMessage($this->getDeviceInfo($requestingDeviceId), MF_SUBSCRIBER);

                    consoleLog("Device {$requestingDeviceId} : {$this->devices[$requestingDeviceId]->employee} logged out.");
                } else {
                    // wrong pin
                    $client->send($this->createResponse(R_DEVICE_LOGOUT_FAILED));
                }
            } else {
                // cant logout
                $client->send($this->createResponse(R_DEVICE_NOT_REGISTERED));
            }
        }
    }



    private function handleSubscription(ConnectionInterface $client, $data)
    {
        if (isset($data->i)) {
            // device id check
            if ($deviceIdToBeSubscribedTo = $this->Database->validateDeviceId($data->i)) {
                if (isset($data->s)) {
                    // check if it is streamer
                    if (!$this->devices[$deviceIdToBeSubscribedTo]->isStreamer($client->resourceId)) {
                        if ($data->s) {
                            // subscribe
                            if ($this->devices[$deviceIdToBeSubscribedTo]->addSubscriber($client->resourceId)) {
                                $client->send($this->createResponse(R_SUBSCRIBER_REGISTERED));
                            } else {
                                $client->send($this->createResponse(R_SUBSCRIBER_ALREADY_REGISTERED));
                            }
                        } else {
                            // unsubscribe
                            if ($this->devices[$deviceIdToBeSubscribedTo]->removeSubscriber($client->resourceId)) {
                                $client->send($this->createResponse(R_SUBSCRIBER_UNREGISTERED));
                            } else {
                                $client->send($this->createResponse(R_SUBSCRIBER_NOT_REGISTERED));
                            }
                        }
                    } else {
                        $client->send($this->createResponse(R_DEVICE_CANT_REGISTER_AS_SUBSCRIBER));
                    }
                } else {
                    $client->send($this->createResponse(R_SUBSCRIBER_MISSING_REGISTRATION_STATE));
                }
            } else {
                $client->send($this->createResponse(R_INVALID_DEVICE_ID));
            }
        } else {
            $client->send($this->createResponse(R_MISSING_DEVICE_ID));
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
            $client->send($this->createResponse(R_DEVICE_NOT_REGISTERED));
        }
    }


    private function updateDevices()
    {
        consoleLog("-> Update devices");
        $deviceList = $this->Database->getDevices();
        // add
        foreach ($deviceList as $deviceData) {
            // add only new devices
            if (isset($this->devices[$deviceData->id]))
                continue;
            $this->devices[$deviceData->id] = new Device($deviceData);
            $device = $this->devices[$deviceData->id];
            consoleLog("--> added id: {$device->id} employee: {$device->employee}");
        }
        // remove
        foreach ($this->devices as $device) {
            $existsInDatabase = false;
            foreach ($deviceList as $deviceData) {
                if ($device->id == $deviceData->id) {
                    $existsInDatabase = true;
                    break;
                }
            }
            if ($existsInDatabase)
                continue;
            consoleLog("--> removed id: {$device->id} employee: {$device->employee}");
            unset($this->devices[$device->id]);
        }
    }

    private function getDeviceIdByResourceId($resourceId)
    {
        foreach ($this->devices as $device) {
            // check if the streamers resource id has been logged in
            if ($device->isStreamer($resourceId))
                return $device->id;
        }
        return false;
    }

    // send to all client is default without flags
    private function sendGlobalMessage($message, $target = 0)
    {
        if ($target & MF_Streamer) {
            foreach ($this->devices as $device) {
                $device->sendStreamer($message);
            }
        }

        if ($target & MF_SUBSCRIBER) {
            foreach ($this->devices as $device) {
                $device->send($message);
            }
        }

        // send to all client is default
        if (($target & MF_CONNECTION) || $target = 0) {
            foreach ($this->clients as $client) {
                $client->send($message);
            }
        }

        if ($target & MF_UNUSED_CONNECTION) {
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
                'employee' => $this->devices[$id]->employee,
                'isConnected' => $this->devices[$id]->isConnected
            ]
        ];
        return json_encode($message);
    }

    private function createResponse($responseId)
    {
        $response = (object)[
            'type' => "response",
            'id' => "{$responseId}"
        ];
        return json_encode($response);
    }
}
