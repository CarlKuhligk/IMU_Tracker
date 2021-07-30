<?php

define('__ROOT__', dirname(dirname(dirname(__FILE__))));

include_once (__ROOT__.'\php\DBController.php');
include_once (__ROOT__.'\php\AssingmentManager.php');
include_once (__ROOT__.'\php\DBConfig.php');


$assingMgr = new AssingmentManager();
$db = new DBController();
if($db->connect($servername, $username, $password, $dbname)){
    echo "db connection sucsessful\n";
}else{
    die("db connection faild!\n");
}

$message = (object)[
    'type'=>"",
    'value'=>""];

// senderID22

$message->type = "sender";
$message->value = "28e7ebccfe374ccf75c3ec83fbc2805ec6131ab4d1aba6d859726e9b99cde835";
echo "senderID22:\n";
print_r($message)."\n";
$senderId22 = json_encode($message);
add(22, $senderId22);


// revicerId90
$message->type = "reciver";
$message->value = 12;
echo "revicerId90:\n";
print_r($message)."\n";
$revicerId90 = json_encode($message);
add(90, $revicerId90);

// revicerId2
$message->type = "reciver";
$message->value = 12;
echo "revicerId2:\n";
print_r($message)."\n";
$revicerId2 = json_encode($message);
add(2, $revicerId2);

// revicerId786
$message->type = "reciver";
$message->value = 12;
echo "revicerId786:\n";
print_r($message)."\n";
$revicerId786 = json_encode($message);
add(786, $revicerId786);

// senderID22 send data
$message->type = "data";
$message->value = array(1,2,3,4,5,6,7);
echo print_r($message);
$senderId22 = json_encode($message);
add(22, $senderId22);

delete(786);
delete(786);
delete(22);

// senderID22

$message->type = "sender";
$message->value = "28e7ebccfe374ccf75c3ec83fbc2805ec6131ab4d1aba6d859726e9b99cde835";
echo "senderID22:\n";
print_r($message)."\n";
$senderId22 = json_encode($message);
add(22, $senderId22);


print_r($assingMgr);

function add($recourceId, $message){
    global $db, $assingMgr;
    $data = json_decode($message);

    if(!isset($data->type) || !isset($data->value)){
        echo "error: data is missing\n";
        return;
    }

    // handle incoming data
    switch ($data->type){
        case "sender":
            // is api key valid?
            if($channel = $db->validateApiKey($data->value)){
                // store sender recource id
                $assingMgr->addSenderRescourceId($recourceId, $channel->id, $channel->dataTableName);
                // update channel status -> online
                $db->setChannelOnline($channel->id);
                echo "sucsessfuly authenticated\n";
            }else{
                echo "error: invailid api key\n";
            }
            break;
        case "reciver":
            // is channel id valid?
            if($channel = $db->validateChannelId($data->value)){
                // store revicers recource id
                $assingMgr->addReciverRescourceId($recourceId, $channel->id, $channel->dataTableName);
                // update reciverRescourceId count -> +1
                $db->setSubscriberCount($channel->id, count($assingMgr->channels[$channel->id]->reciverRescourceIds));
                echo "sucsessfuly subscribed\n";
            }else{
                echo "error: invailid channel id\n";
            }
            break;
        case "data":
            $authenticated = false;
            foreach($assingMgr->channels as $channel){
                // check if the senders recource id has been authenticated
                if($channel->senderRescourceId === $recourceId){
                    $authenticated = true;
                    // write values in database
                    $db->writeSensorData($channel->dataTableName, $data->value);
                    // send values to all channel subscribers
                    foreach($assingMgr->channels[$channel->id]->reciverRescourceIds as $reciverRescourceId){
                        echo "Send message to reciverRescourceId Id: ".$reciverRescourceId."\n";
                    }
                }
            }
            if(!$authenticated){
                echo "error: not authenticated\n";
            }
            break;
        default:
            echo "error: unknown type\n";
    }
}



function delete($resourceId){
    global $db, $assingMgr;

    foreach($assingMgr->channels as $channel){
        // sender?
        if($channel->senderRescourceId === $resourceId){
            // remove sender
            $db->setChannelOffline($channel->id);
            $assingMgr->removeSenderRescourceId($resourceId, $channel->id);
            
        }
        // check all reciver of this channel
        foreach($channel->reciverRescourceIds as $reciverRescourceId){
            // reciver?
            if($reciverRescourceId === $resourceId){
                // remove reciver
                $assingMgr->removeReciverRescourceId($reciverRescourceId, $channel->id);
                $db->setSubscriberCount($channel->id, count($assingMgr->channels[$channel->id]->reciverRescourceIds));
                
            }
        }
    }
}





?>