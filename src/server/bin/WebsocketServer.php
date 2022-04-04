<?php

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use SecurityMotionTrackerCommunication\SocketController;

require dirname(__DIR__) . '/vendor/autoload.php';

$SecurityMotionTrackerWsServer = new SocketController();

$server = IoServer::factory(new HttpServer(new WsServer($SecurityMotionTrackerWsServer)), 8080);

// starting watchdog
$server->loop->addPeriodicTimer(1, function () use ($SecurityMotionTrackerWsServer) {
    $SecurityMotionTrackerWsServer->watchDog();
});

$server->run();

// server closed
echo "Server has stopped!";
