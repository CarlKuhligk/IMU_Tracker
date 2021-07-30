<?php
namespace IMUSocketCommunication;
use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

include_once 'DBController.php';
include_once 'DBConfig.php';
include_once 'AssingmentManager.php';

use DBController;
use DBConfig;
use AssingmentManager;


class SocketController extends DBConfig implements MessageComponentInterface{
    protected $clients;

    private $assingMgr;
    private $db;


    public function __construct() {
        $this->clients = [];
        $this->assingMgr = new AssingmentManager();
        $this->db = new DBController();
        if($this->db->connect($this->servername, $this->username, $this->password, $this->dbname) === false){
            die("Connection to database faild!");
        }
    }

    public function onOpen(ConnectionInterface $clientConnection) {
        // Store the new connection to send messages to later
        $this->clients[$clientConnection->resourceId] = $clientConnection;
        echo "New connection! ({$clientConnection->resourceId})\n";
    }

    public function onMessage(ConnectionInterface $from, $message) {
        // convert string to object
        $data = json_decode($message);

        // break if data is missing
        if(!isset($data->type) || !isset($data->value)){
            $from->send("error: data is missing\n");
            return;
        }

        // handle incoming data
        switch ($data->type){
            case "sender":
                // is api key valid?
                if($channel = $this->db->validateApiKey($data->value)){
                    // store sender recource id
                    $this->assingMgr->addSenderRescourceId($from->resourceId, $channel->id, $channel->dataTableName);
                    // update channel status -> online
                    $this->db->setChannelOnline($channel->id);
                    $from->send("sucsessfuly authenticated\n");
                }else{
                    $from->send("error: invailid api key\n");
                }
                break;
            case "reciver":
                // is channel id valid?
                if($channel = $this->db->validateChannelId($data->value)){
                    // store revicers recource id
                    $this->assingMgr->addReciverRescourceId($from->resourceId, $channel->id, $channel->dataTableName);
                    $this->db->setSubscriberCount($channel->id, count($this->assingMgr->channels[$channel->id]->reciverRescourceIds));
                    $from->send("sucsessfuly subscribed\n");
                }else{
                    $from->send("error: invailid channel id\n");
                }
                break;
            case "data":
                for($i = 0; $i < 7; $i++){
                    // check if is empty or not a number
                    if($data->value[$i] == null || !is_numeric($data->value[$i] + 0)){
                        $from->send("error: data is missing\n");
                        return;
                    }
                }
                $authenticated = false;
                foreach($this->assingMgr->channels as $channel){
                    // check if the senders recource id has been authenticated
                    if($channel->senderRescourceId === $from->resourceId){
                        $authenticated = true;
                        // write values in database
                        $this->db->writeSensorData($channel->dataTableName, $data->value);
                        // send values to all "channel/channel" subscribers
                        foreach($this->assingMgr->channels[$channel->id]->reciverRescourceIds as $reciverRescourceId){
                            $this->clients[$reciverRescourceId]->send($message);
                        }
                    }
                }
                if(!$authenticated){
                    $from->send("error: not authenticated\n");
                }
                break;
            default:
                $from->send("error: unknown type\n");
        }
    }

    public function onClose(ConnectionInterface $clientConnection) {

        foreach($this->assingMgr->channels as $channel){
            // sender?
            if($channel->senderRescourceId === $clientConnection->resourceId){
                // remove sender
                $this->db->setChannelOffline($channel->id);
                $this->assingMgr->removeSenderRescourceId($clientConnection->resourceId, $channel->id);
                
            }
            // check all reciver of this channel
            foreach($channel->reciverRescourceIds as $reciverRescourceId){
                // reciver?
                if($reciverRescourceId === $clientConnection->resourceId){
                    // remove reciver
                    $this->assingMgr->removeReciverRescourceId($reciverRescourceId, $channel->id);
                    $this->db->setSubscriberCount($channel->id, count($this->assingMgr->channels[$channel->id]->reciverRescourceIds));
                }
            }
        }
        // The connection is closed, remove it, as we can no longer send it messages
        unset($this->clients[$clientConnection->resourceId]);

        echo "Connection {$clientConnection->resourceId} has disconnected\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e) {
        echo "An error has occurred: {$e->getMessage()}\n";

        $conn->close();
    }
}