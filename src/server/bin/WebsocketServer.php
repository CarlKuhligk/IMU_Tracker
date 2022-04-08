<?php

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use SecurityMotionTrackerCommunication\SocketController;

require dirname(__DIR__) . '/vendor/autoload.php';

$SecurityMotionTrackerWsServer = new SocketController();

$server = IoServer::factory(new HttpServer(new WsServer($SecurityMotionTrackerWsServer)), 8080);

// used for monitoring idle and connection lost time
$server->loop->addPeriodicTimer(1, function () use ($SecurityMotionTrackerWsServer) {
    $SecurityMotionTrackerWsServer->watchDogA();
});

// used for removing obsolete data in database
$server->loop->addPeriodicTimer(600, function () use ($SecurityMotionTrackerWsServer) {
    $SecurityMotionTrackerWsServer->watchDogB();
});

$server->run();

// server closed
echo "Server has stopped!";
