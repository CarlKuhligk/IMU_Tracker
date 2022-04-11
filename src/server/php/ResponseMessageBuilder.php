<?php
# responses
include_once 'ResponseList.php';

//#region [AppClientMessages]
function buildUpdateDeviceSettingsForAppClientResponseMessage($device)
{
    $settingsMessage = (object)[
        't' => "s",
        'it' => $device->settings->idleTimeout,
        'b' => $device->settings->batteryWarning,
        'c' => $device->settings->connectionTimeout,
        'm' => $device->settings->measurementInterval,
        'ai' => $device->settings->accelerationMax,
        'a' => $device->settings->accelerationMin,
        'ri' => $device->settings->rotationMin,
        'r' => $device->settings->rotationMax
    ];
    return json_encode($settingsMessage);
}
//#endregion


function buildResponseMessage($responseId)
{
    $response = (object)[
        't' => "r",
        'i' => $responseId
    ];
    return json_encode($response);
}


//#region [WebClientMessages]
function buildDeviceCreatedResponseMessage($newApikey)
{
    $response = (object)[
        't' => "k",
        'a' => "{$newApikey}"
    ];
    return json_encode($response);
}
//#endregion


//#region [GlobalMessages]
function buildUpdateConnectionResponseMessage($id, $state)
{
    $isConnected = 0;
    if ($state) $isConnected = 1;

    $response = (object)[
        't' => "uc",
        'i' => $id,
        'c' => $isConnected
    ];
    return json_encode($response);
}

function buildAddMeasurementResponseMessage($measurements)
{
    $response = (object)[
        't' => "M",
        'd' => $measurements
    ];
    return json_encode($response);
}

function buildAddEventResponseMessage($eventList)
{
    $response = (object)[
        't' => "e",
        'd' => $eventList
    ];
    return json_encode($response);
}

function buildUpdateDeviceSettingsForWebClientResponseMessage($device)
{
    $response = (object)[
        't' => "su",
        'i' => $device->id,
        'it' => $device->settings->idleTimeout,
        'b' => $device->settings->batteryWarning,
        'c' => $device->settings->connectionTimeout,
        'm' => $device->settings->measurementInterval,
        'ai' => $device->settings->accelerationMin,
        'a' => $device->settings->accelerationMax,
        'ri' => $device->settings->rotationMin,
        'r' => $device->settings->rotationMax
    ];
    return json_encode($response);
}

function buildAddDeviceResponseMessage($deviceList)
{
    $convertedDEviceList = array();

    foreach ($deviceList as $device) {
        $convertedDevice = (object)[
            'i' => $device->id,
            'e' => "{$device->employee}",
            'it' => $device->settings->idleTimeout,
            'b' => $device->settings->batteryWarning,
            'c' => $device->settings->connectionTimeout,
            'm' => $device->settings->measurementInterval,
            'ai' => $device->settings->accelerationMin,
            'a' => $device->settings->accelerationMax,
            'ri' => $device->settings->rotationMin,
            'r' => $device->settings->rotationMax
        ];
        array_push($convertedDEviceList, $convertedDevice);
    }

    $response = (object)[
        't' => "ad",
        'd' => $convertedDEviceList
    ];
    return json_encode($response);
}

function buildRemoveDeviceResponseMessage($id)
{
    $response = (object)[
        't' => "rd",
        'i' => $id
    ];
    return json_encode($response);
}

//#endregion

function buildMeasurement($id, $data, $timestamp)
{
    $measurements = (object)[
        'i' => $id,
        't' => "{$timestamp}",
        'a' => $data->a,
        'r' => $data->r,
        'tp' => $data->tp,
        'b' => $data->b

    ];
    return $measurements;
}


function buildEventList($deviceId, $eventIdList)
{
    $events = array();

    foreach ($eventIdList as $eventId) {
        $event = (object)[
            'i' => $deviceId,
            'e' => $eventId
        ];
        array_push($events, $event);
    }
    return $events;
}
