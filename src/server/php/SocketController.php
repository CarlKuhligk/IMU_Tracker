<?php

namespace SecurityMotionTrackerCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;


include_once 'Console.php';
include_once 'DBController.php';
include_once 'Device.php';
include_once 'ResponseList.php';

use DBController;
use Device;

// MessageFlags
define("MF_SUBSCRIBER", 1 << 1);
define("MF_STREAMER", 1 << 2);
define("MF_CONNECTION", 1 << 3);


class SocketController implements MessageComponentInterface
{
    private $subscriberList = array();  // stores resources id's of subscribers (web client)
    private $clientList = array();      // stores ConnectionInterface objects
    private $deviceList = array();      // stores Devices objects
    private DBController $Database;

    function __construct()
    {
        $this->Database = new DBController(getenv("MYSQL_HOST"), getenv("MYSQL_USER"), getenv("MYSQL_PASSWORD"), getenv("MYSQL_DATABASE"));

        // try to connect to database
        if ($this->Database->connect() == false) {
            die("Check your database server!\n");
        }
        consoleLog("Start system:");
        consoleLog("-> Reset online state");
        $this->Database->resetDevicesIsConnected();
        $this->updateDeviceList();
        consoleLog("System has started");
        // set static references
        Device::$Database = &$this->Database;
        Device::$clientList = &$this->clientList;
    }

    public function onOpen(ConnectionInterface $client)
    {
        // store the new unassigned connection
        $this->clientList[$client->resourceId] = $client;
        consoleLog("New unassigned connection! Client id: {$client->resourceId} source: {$client->remoteAddress}");
    }

    public function onMessage(ConnectionInterface $client, $message)
    {
        $data = json_decode($message);

        // check if the websocket message type is set (see websocket communication diagram)
        if (isset($data->t)) {
            $this->handleMessage($client, $data);
        } else {
            $client->send($this->createResponseMessage(R_MISSING_TYPE));
            return;
        }
    }


    public function onClose(ConnectionInterface $client)
    {
        // handle special case if the client is a streamer
        if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
            $device = $this->deviceList[$requestingDeviceId];
            // validate correct logout otherwise generate connection lost event
            if ($eventId = $device->connectionClosed()) {
                // event connection lost
                //#region [keepInMind]
                consoleLog("EVENT: CONNECTION LOST!");
                //#endregion
                consoleLog("Device {$requestingDeviceId} : {$this->deviceList[$requestingDeviceId]->employee} lost connection.");
            }
            $this->sendGlobalMessage($this->createConnectionUpdateMessage($device->id), MF_SUBSCRIBER);
        }
        // remove if it is a subscriber (web client)
        elseif (in_array($client->resourceId, $this->subscriberList)) {
            unset($this->subscriberList[$client->resourceId]);
        }
        consoleLog("Client {$client->resourceId} has disconnected");
        // The connection is closed, remove it, as we can no longer send it messages
        unset($this->clientList[$client->resourceId]);
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
                $client->send($this->createResponseMessage(R_UNKNOWN_DATA_TYPE));
        }
    }

    private function handleLogin(ConnectionInterface $client, $data)
    {
        if (isset($data->a)) {
            // check if key is valid
            if ($requestingDeviceId = $this->Database->validateKey($data->a)) {
                // check if device is loaded otherwise reload deviceList and proceed
                if (!array_key_exists($requestingDeviceId, $this->deviceList))
                    $this->updateDeviceList();
                $device = $this->deviceList[$requestingDeviceId];
                // check if device is already registered
                if ($device->isConnected) {
                    $client->send($this->createResponseMessage(R_DEVICE_ALREADY_REGISTERED));
                } else {
                    // check if device has subscribed
                    if (in_array($client->resourceId, $this->subscriberList)) {
                        $client->send($this->createResponseMessage(R_SUBSCRIBER_CANT_REGISTER_AS_STREAMER));
                    } else {
                        $device->login($client->resourceId);
                        $client->send($this->createResponseMessage(R_DEVICE_REGISTERED));
                        $device->sendSettings(); // send recent settings
                        $this->sendGlobalMessage($this->createConnectionUpdateMessage($requestingDeviceId), MF_SUBSCRIBER);
                        consoleLog("Device {$requestingDeviceId} Employee: {$device->employee} logged in.");
                    }
                }
            } else {
                $client->send($this->createResponseMessage(R_INVALID_API_KEY));
            }
        } else {
            $client->send($this->createResponseMessage(R_MISSING_API_KEY));
        }
    }


    private function handleLogout(ConnectionInterface $client, $data)
    {
        if (isset($data->p)) {
            if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
                $device = $this->deviceList[$requestingDeviceId];
                // try logout
                $pinIsCorrect = $this->Database->validatePin($data->p, $device); // check pin
                if ($pinIsCorrect) {
                    $device->logout();
                    $client->send($this->createResponseMessage(R_DEVICE_LOGGED_OUT));
                    $this->sendGlobalMessage($this->createConnectionUpdateMessage($requestingDeviceId), MF_SUBSCRIBER);
                    consoleLog("Device {$requestingDeviceId} : {$device->employee} logged out.");
                } else {
                    // wrong pin
                    $client->send($this->createResponseMessage(R_DEVICE_LOGOUT_FAILED));
                }
            } else {
                // cant logout
                $client->send($this->createResponseMessage(R_DEVICE_NOT_REGISTERED));
            }
        } else
            // pin is missing
            $client->send($this->createResponseMessage(R_MISSING_PIN));
    }


    private function handleSubscription(ConnectionInterface $client, $data)
    {
        if (isset($data->s)) {
            // try register
            if ($data->s) {
                // check if the resource id is registered
                if (in_array($client->resourceId, $this->subscriberList)) {
                    $client->send($this->createResponseMessage(R_SUBSCRIBER_ALREADY_REGISTERED));
                }

                // check if the resource id is registered as streamer device
                elseif ($this->getDeviceIdByResourceId($client->resourceId)) {
                    $client->send($this->createResponseMessage(R_STREAMER_CANT_REGISTER_AS_SUBSCRIBER));
                }

                // assign/register client as subscriber
                else {
                    array_push($this->subscriberList, $client->resourceId);
                    $client->send($this->createResponseMessage(R_SUBSCRIBER_REGISTERED));
                }
            }
            // try unregister
            else {
                // check if the client is registered as subscriber
                if (!in_array($client->resourceId, $this->subscriberList)) {
                    $client->send($this->createResponseMessage(R_SUBSCRIBER_NOT_REGISTERED));
                }

                // unregister client as subscriber
                else {
                    unset($this->subscriberList[$client->resourceId]);
                    $client->send($this->createResponseMessage(R_SUBSCRIBER_UNREGISTERED));
                }
            }
        } else {
            $client->send($this->createResponseMessage(R_SUBSCRIBER_MISSING_REGISTRATION_STATE));
        }
    }


    private function handleNewTrackingData(ConnectionInterface $client, $data)
    {
        // validate that the client is registered as streamer
        if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
            $device = $this->deviceList[$requestingDeviceId];
            $device->processTrackingData($data);
        } else {
            $client->send($this->createResponseMessage(R_DEVICE_NOT_REGISTERED));
        }
    }


    private function updateDeviceList()
    {
        consoleLog("-> Update deviceList");
        $deviceList = $this->Database->getDevices();
        // add devices to the list
        foreach ($deviceList as $deviceData) {
            // add only new deviceList
            if (isset($this->deviceList[$deviceData->id]))
                continue;
            $this->deviceList[$deviceData->id] = new Device($deviceData);
            $device = $this->deviceList[$deviceData->id];
            consoleLog("--> added id: {$device->id} employee: {$device->employee}");
        }
        // remove devices from list
        foreach ($this->deviceList as $device) {
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
            unset($this->deviceList[$device->id]);
        }
    }

    private function getDeviceIdByResourceId($resourceId)
    {
        foreach ($this->deviceList as $device) {
            // check if the streamers resource id has been logged in
            if ($device->isStreamer($resourceId))
                return $device->id;
        }
        return false;
    }


    public function watchDog()
    {
        foreach ($this->deviceList as $device) {
            $events = $device->monitoringTimeouts();
            if (isset($events))
                foreach ($events as $event) {
                    #################################e
                    # send event
                    #34##################################
                }
        }
    }

    // sends a message to the specified groupe (by default to all open connections)
    private function sendGlobalMessage($message, $target = 0)
    {
        // send message to ALL streaming devices 
        if ($target & MF_STREAMER) {
            foreach ($this->deviceList as $device) {
                $device->sendToStreamingDevice($message);
            }
        }

        // send message to ALL subscriber
        if ($target & MF_SUBSCRIBER) {
            foreach ($this->subscriberList as $subscriberResourceId) {
                $this->clientList[$subscriberResourceId]->send($message);
            }
        }

        // send to all client by default
        if (($target & MF_CONNECTION) || $target = 0) {
            foreach ($this->clientList as $client) {
                $client->send($message);
            }
        }
    }

    private function createConnectionUpdateMessage(int $id)
    {
        $device = $this->deviceList[$id];

        $message = (object)[
            't' => "u",
            'i' => $id,
            'c' => $device->isConnected
        ];
        return json_encode($message);
    }

    private function createResponseMessage($responseId)
    {
        $response = (object)[
            't' => "r",
            'i' => "{$responseId}"
        ];
        return json_encode($response);
    }

    private function createEventResponseMessage($deviceId, $eventId)
    {
        $response = (object)[
            't' => "e",
            'e' => "{$eventId}",
            'i' => "{$deviceId}"
        ];
        return json_encode($eventId);
    }
}
