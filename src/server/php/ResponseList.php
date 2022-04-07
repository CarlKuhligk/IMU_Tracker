<?php
# responses
define("R_NOT_CONNECTED", 1);
define("R_CONNECTED", 2);
define("R_GLOBAL_UPDATE", 4);

define("R_DEVICE_LOGOUT_FAILED", 8);
define("R_DEVICE_LOGGED_OUT", 9);

define("R_DEVICE_REGISTERED", 10);
define("R_SUBSCRIBER_REGISTERED", 11);
define("R_SUBSCRIBER_UNREGISTERED", 12);

define("R_MISSING_PIN", 18);
define("R_MISSING_API_KEY", 19);
define("R_INVALID_API_KEY", 20);
define("R_DEVICE_ALREADY_REGISTERED", 21);
define("R_DEVICE_NOT_REGISTERED", 22);
define("R_INVALID_DEVICE_ID", 23);
define("R_SUBSCRIBER_ALREADY_REGISTERED", 24);
define("R_SUBSCRIBER_NOT_REGISTERED", 25);
define("R_MISSING_DEVICE_ID", 26);
define("R_SUBSCRIBER_MISSING_REGISTRATION_STATE", 27);
define("R_SUBSCRIBER_CANT_REGISTER_AS_STREAMER", 28);
define("R_STREAMER_CANT_REGISTER_AS_SUBSCRIBER", 29);
define("R_MISSING_TYPE", 30);
define("R_MISSING_DATA", 31);
define("R_UNKNOWN_DATA_TYPE", 32);
define("R_NOT_AUTHORIZED", 33);
define("R_KEY_IS_VALID", 34);

define("R_SERVER_OFFLINE", 40);
define("R_UNKNOWN_ERROR", 42);


function createMeasurementOutResponseMessage($id, $measurement)
{
    $response = (object)[
        't' => "M",
        'i' => "{$id}",
        'a' => "{$measurement->a}",
        'r' => "{$measurement->r}",
        'tp' => "{$measurement->tp}",
        'b' => "{$measurement->b}",
    ];
    return json_encode($response);
}

function createAddDeviceResponseMessage($deviceList)
{
    $convertedDEviceList = array();

    foreach ($deviceList as $device) {
        $convertedDevice = (object)[
            'i' => "{$device->id}",
            'e' => "{$device->employee}",
            'it' => "{$device->settings->idleTimeout}",
            'b' => "{$device->settings->batteryWarning}",
            'c' => "{$device->settings->connectionTimeout}",
            'm' => "{$device->settings->measurementInterval}",
            'ai' => "{$device->settings->accelerationMin}",
            'a' => "{$device->settings->accelerationMax}",
            'ri' => "{$device->settings->rotationMin}",
            'r' => "{$device->settings->rotationMax}",
        ];
        array_push($convertedDEviceList, $convertedDevice);
    }

    $response = (object)[
        't' => "ad",
        'd' => $convertedDEviceList
    ];
    return json_encode($response);
}

function createUpdateConnectionResponseMessage($id, $state)
{
    $response = (object)[
        't' => "uc",
        'i' => "{$id}",
        'c' => "{$state}"
    ];
    return json_encode($response);
}

function createResponseMessage($responseId)
{
    $response = (object)[
        't' => "r",
        'i' => "{$responseId}"
    ];
    return json_encode($response);
}

function createEventResponseMessage($deviceId, $eventId)
{
    $response = (object)[
        't' => "e",
        'e' => "{$eventId}",
        'i' => "{$deviceId}"
    ];
    return json_encode($response);
}

function createDeviceCreatedResponseMessage($newApikey)
{
    $response = (object)[
        't' => "k",
        'a' => "{$newApikey}"
    ];
    return json_encode($response);
}
