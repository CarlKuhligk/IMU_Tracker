<?php

namespace SecurityMotionTrackerCommunication;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

include_once 'Console.php';
include_once 'DBController.php';
include_once 'Device.php';
include_once 'ResponseMessageBuilder.php';
include_once 'EventList.php';

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
    private $eventList = array();
    private $dataIsObsoleteAfterNDays;
    private $watchdogAIsActive = false;
    private $watchdogBIsActive = false;

    function __construct()
    {
        $this->dataIsObsoleteAfterNDays =  getenv("OBSOLETE_AFTER_DAYS");
        $this->Database = new DBController(getenv("MYSQL_HOST"), getenv("MYSQL_USER"), getenv("MYSQL_PASSWORD"), getenv("MYSQL_DATABASE"));

        // try to connect to database
        if ($this->Database->connect() === false) {
            die("Check your database server!\n");
        }
        consoleLog("Setting: Data is obsolete after {$this->dataIsObsoleteAfterNDays} days.");
        consoleLog("Version: " .  getenv("VERSION"));
        consoleLog("Start system:");
        // set static references
        Device::$Database = &$this->Database;
        Device::$clientList = &$this->clientList;
        Device::$eventList = &$this->eventList;
        consoleLog("-> Reset online state");
        $this->Database->resetDevicesIsConnected();
        consoleLog("-> Update device list");
        $this->updateDeviceList();

        consoleLog("-> Loading measurements");
        $totalMeasurements = 0;
        foreach ($this->deviceList as $device) {
            $loadedMeasurements = $device->loadMeasurements();
            consoleLog("--> id:{$device->id} measurements: {$loadedMeasurements}");
            $totalMeasurements += $loadedMeasurements;
        }
        consoleLog("-> {$totalMeasurements} Measurements loaded");
        unset($totalMeasurements);

        consoleLog("-> Loading events");
        $this->eventList = $this->Database->loadEvents();
        $eventCount = count($this->eventList);
        consoleLog("-> {$eventCount} Events loaded");
        unset($eventCount);

        consoleLog("-> Enable watchdog a");
        $this->watchdogAIsActive = true;
        consoleLog("-> Enable watchdog b");
        $this->watchdogBIsActive = true;
        consoleLog("System has started");
    }

    function serverStop()
    {
        consoleLog("Stop system:");
        consoleLog("-> Close all " . count($this->clientList) . " active connections.");
        foreach ($this->clientList as $client) {
            $client->close();
        }
    }


    public function onOpen(ConnectionInterface $client)
    {
        // store the new unassigned connection
        $this->clientList[$client->resourceId] = $client;
        consoleLog("Client {$client->resourceId} connected. Source: {$client->remoteAddress}");
    }

    public function onMessage(ConnectionInterface $client, $message)
    {
        $data = json_decode($message);

        // check if the websocket message type is set (see websocket communication diagram)
        if (isset($data->t)) {
            $this->handleMessage($client, $data);
        } else {
            $client->send(buildResponseMessage(R_MISSING_TYPE));
            return;
        }
    }

    public function onClose(ConnectionInterface $client)
    {
        // handle special case if the client is a streamer
        if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
            $device = $this->deviceList[$requestingDeviceId];
            $this->sendGlobalMessage(buildUpdateConnectionResponseMessage($device->id, false), MF_SUBSCRIBER);
            // validate correct logout otherwise generate connection lost event
            //#region [events]
            $eventContainer = $device->connectionClosed();
            $this->sendGlobalMessage(buildAddEventResponseMessage($device->id, $eventContainer), MF_SUBSCRIBER);
            //#endregion
            consoleLog("Device {$requestingDeviceId} lost connection.");
        }
        // remove if it is a subscriber (web client)
        elseif (in_array($client->resourceId, $this->subscriberList)) {
            $this->removeSubscriber($client->resourceId);
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
            case "i":
                $this->handleLogin($client, $data);
                break;
            case "o":
                $this->handleLogout($client, $data);
                break;
            case "s":
                $this->handleSubscription($client, $data);
                break;
            case "m":
                $this->handleNewTrackingData($client, $data);
                break;
            case "S":
                $this->handleChangeSettings($client, $data);
                break;
            case "A":
                $this->handleCreateNewDevice($client, $data);
                break;
            case "R":
                $this->handleRemoveDevice($client, $data);
                break;
            default:
                $client->send(buildResponseMessage(R_UNKNOWN_DATA_TYPE));
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
                    $client->send(buildResponseMessage(R_DEVICE_ALREADY_REGISTERED));
                } elseif ($device->isObsolete) {
                    $client->send(buildResponseMessage(R_KEY_IS_NOT_LONGER_VALID));
                } else {
                    // check if device has subscribed
                    if (in_array($client->resourceId, $this->subscriberList)) {
                        $client->send(buildResponseMessage(R_SUBSCRIBER_CANT_REGISTER_AS_STREAMER));
                    } else {
                        if ($data->c) {
                            $client->send(buildResponseMessage(R_KEY_IS_VALID));
                        } else {
                            $eventContainer = $device->login($client->resourceId);
                            $client->send(buildResponseMessage(R_DEVICE_REGISTERED));
                            $client->send(buildUpdateDeviceSettingsForAppClientResponseMessage($device));
                            $this->sendGlobalMessage(buildUpdateConnectionResponseMessage($device->id, true), MF_SUBSCRIBER);
                            $this->sendGlobalMessage(buildAddEventResponseMessage($device->id, $eventContainer), MF_SUBSCRIBER);
                            consoleLog("Device {$device->id} logged in.");
                        }
                    }
                }
            } else {
                $client->send(buildResponseMessage(R_INVALID_API_KEY));
            }
        } else {
            $client->send(buildResponseMessage(R_MISSING_API_KEY));
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
                    $client->send(buildResponseMessage(R_DEVICE_LOGGED_OUT));
                    $this->sendGlobalMessage(buildUpdateConnectionResponseMessage($device->id, false), MF_SUBSCRIBER);
                    consoleLog("Device {$device->id} logged out.");
                } else {
                    // wrong pin
                    $client->send(buildResponseMessage(R_DEVICE_LOGOUT_FAILED));
                }
            } else {
                // cant logout
                $client->send(buildResponseMessage(R_DEVICE_NOT_REGISTERED));
            }
        } else
            // pin is missing
            $client->send(buildResponseMessage(R_MISSING_PIN));
    }

    private function handleSubscription(ConnectionInterface $client, $data)
    {
        if (isset($data->s)) {
            // try register
            if ($data->s) {
                // check if the resource id is registered
                if (in_array($client->resourceId, $this->subscriberList)) {
                    $client->send(buildResponseMessage(R_SUBSCRIBER_ALREADY_REGISTERED));
                }

                // check if the resource id is registered as streamer device
                elseif ($this->getDeviceIdByResourceId($client->resourceId)) {
                    $client->send(buildResponseMessage(R_STREAMER_CANT_REGISTER_AS_SUBSCRIBER));
                }

                // register client as subscriber
                else {
                    array_push($this->subscriberList, $client->resourceId);
                    $client->send(buildResponseMessage(R_SUBSCRIBER_REGISTERED));
                    if (count($this->deviceList) > 0) {
                        $client->send(buildAddDeviceResponseMessage($this->deviceList));

                        foreach ($this->deviceList as $device) {
                            $client->send(buildUpdateConnectionResponseMessage($device->id, $device->isConnected));
                        }

                        //#region [events]
                        $client->send(buildInitAddEventResponseMessage($this->eventList));
                        //#endregion
                    }
                    consoleLog("Client {$client->resourceId} subscribed.");
                }
            }
            // try unregister
            else {
                // check if the client is registered as subscriber
                if (!in_array($client->resourceId, $this->subscriberList)) {
                    $client->send(buildResponseMessage(R_SUBSCRIBER_NOT_REGISTERED));
                }

                // unregister client as subscriber
                else {
                    $this->removeSubscriber($client->resourceId);
                    $client->send(buildResponseMessage(R_SUBSCRIBER_UNREGISTERED));
                    consoleLog("Client {$client->resourceId} unsubscribed");
                }
            }
        } else {
            $client->send(buildResponseMessage(R_SUBSCRIBER_MISSING_REGISTRATION_STATE));
        }
    }

    //#region [events]
    private function handleNewTrackingData(ConnectionInterface $client, $data)
    {
        // validate that the client is registered as streamer
        if ($requestingDeviceId = $this->getDeviceIdByResourceId($client->resourceId)) {
            $device = $this->deviceList[$requestingDeviceId];
            $eventContainer = $device->processTrackingData($data);

            $measurementMessage = buildDeviceMeasurement($device->id, $data, $eventContainer->timestamp);
            $this->sendGlobalMessage(buildAddMeasurementResponseMessage([$measurementMessage]), MF_SUBSCRIBER);
            $this->sendGlobalMessage(buildAddEventResponseMessage($device->id, $eventContainer), MF_SUBSCRIBER);
        } else {
            $client->send(buildResponseMessage(R_DEVICE_NOT_REGISTERED));
        }
    }
    //#endregion

    private function handleChangeSettings(ConnectionInterface $client, $data)
    {
        // check if the resource id is registered
        if (in_array($client->resourceId, $this->subscriberList)) {
            if (isset($data->i)) {
                // check if device id is valid
                if (array_key_exists($data->i, $this->deviceList)) {
                    $device = $this->deviceList[$data->i];
                    $device->updateSettings($data);
                    if ($device->isConnected)
                        $device->sendToStreamingDevice(buildUpdateDeviceSettingsForAppClientResponseMessage($device));
                    $this->sendGlobalMessage(buildUpdateDeviceSettingsForWebClientResponseMessage($device), MF_SUBSCRIBER);
                } else
                    $client->send(buildResponseMessage(R_INVALID_DEVICE_ID));
            } else
                $client->send(buildResponseMessage(R_MISSING_DEVICE_ID));
        } else
            $client->send(buildResponseMessage(R_NOT_AUTHORIZED));
    }

    private function handleCreateNewDevice(ConnectionInterface $client, $data)
    {
        // check if the resource id is registered
        if (in_array($client->resourceId, $this->subscriberList)) {
            $result = $this->Database->buildDevice($data);
            $client->send(buildDeviceCreatedResponseMessage($result->apikey));
            $this->updateDeviceList();
            $newDevice = [$this->deviceList[$result->id]];
            $this->sendGlobalMessage(buildAddDeviceResponseMessage($newDevice), MF_SUBSCRIBER);
        } else
            $client->send(buildResponseMessage(R_NOT_AUTHORIZED));
    }
    private function handleRemoveDevice(ConnectionInterface $client, $data)
    {
        // check if the resource id is registered
        if (in_array($client->resourceId, $this->subscriberList)) {
            if (isset($data->i)) {
                // check if device id is valid
                if (array_key_exists($data->i, $this->deviceList)) {
                    $device = $this->deviceList[$data->i];
                    if ($device->isConnected) {
                        // device is connected lets close the connection and prevent re login 
                        $device->isObsolete = true;
                        $this->clientList[$device->streamerResourceId]->close();
                    }
                    $this->Database->removeDevice($device->id);
                    $this->sendGlobalMessage(buildRemoveDeviceResponseMessage($device->id), MF_SUBSCRIBER);
                    // finally remove the device from the server internal device list
                    $this->updateDeviceList();
                } else
                    $client->send(buildResponseMessage(R_INVALID_DEVICE_ID));
            } else
                $client->send(buildResponseMessage(R_MISSING_DEVICE_ID));
        } else
            $client->send(buildResponseMessage(R_NOT_AUTHORIZED));
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
            $loadedMeasurements = $device->loadMeasurements();
            consoleLog("--> added id: {$device->id} employee: {$device->employee} measurements: {$loadedMeasurements}");
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

    private function removeSubscriber($resourceId)
    {
        $key = array_search($resourceId, $this->subscriberList);
        unset($this->subscriberList[$key]);
    }

    //#region [events]
    public function watchDogA()
    {
        if ($this->watchdogAIsActive) {
            if (count($this->deviceList) > 0) {
                foreach ($this->deviceList as $device) {
                    $eventContainer = $device->monitoringTimeouts();
                    if (isset($eventContainer)) {
                        if (count($eventContainer->events) > 0) {
                            $this->sendGlobalMessage(buildAddEventResponseMessage($device->id, $eventContainer), MF_SUBSCRIBER);
                        }
                    }
                }
            }
        }
    }
    //#endregion

    public function watchDogB()
    {
        if ($this->watchdogBIsActive) {
            // delete obsolete data
            $this->Database->removeObsoleteData($this->dataIsObsoleteAfterNDays);
            consoleLog("Auto cleanup: Remove obsolete data older as {$this->dataIsObsoleteAfterNDays} day's.");
        }
    }

    // sends a message to the specified groupe (by default to all open connections)
    private function sendGlobalMessage($message, $target = 0)
    {
        if (isset($message)) {
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
    }
}
