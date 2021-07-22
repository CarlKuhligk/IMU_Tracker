<?php

/*
  Rui Santos
  Complete project details at https://RandomNerdTutorials.com/esp32-esp8266-mysql-database-php/
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files.
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
*/

$servername = "localhost";
$dbname = "imutracker";
$username = "imuAPI";
$password = "Cs.![qPtTOAVxs].";

// api keys stored in the database
$api_key_value = "kzNABRcbVBQghFDC";

$api_key = $id = $time = $accX = $accY = $accZ = $gyrX = $gyrY = $gyrZ = $temp = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $api_key = htmlspecialchars($_POST["api_key"]);
    if($api_key == $api_key_value) {
        $accX = htmlspecialchars($_POST["accX"]);
        $accY = htmlspecialchars($_POST["accY"]);
        $accZ = htmlspecialchars($_POST["accZ"]);
        $gyrX = htmlspecialchars($_POST["gyrX"]);
        $gyrY = htmlspecialchars($_POST["gyrY"]);
        $gyrZ = htmlspecialchars($_POST["gyrZ"]);
        $temp = htmlspecialchars($_POST["temp"]);
    
        // Create connection
        $conn = new mysqli($servername, $username, $password, $dbname);
        // Check connection
        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        } 
        
        // update always the oldest entry
        $sql = "UPDATE measures SET accX=$accX, accY=$accY, accZ=$accZ, gyrX=$gyrX, gyrY=$gyrY, gyrZ=$gyrZ, temp=$temp WHERE timestamp = (SELECT MIN(timestamp) FROM measures) ORDER BY id LIMIT 1";
        
        if ($conn->query($sql) === TRUE) {
            echo "Entry updated successfully";
        } 
        else {
            echo "Error: " . $sql . "<br>" . $conn->error;
        }
    
        $conn->close();
    }
    else {
        echo "Wrong API Key provided.";
    }

}
else {
    echo "No data posted with HTTP POST.";
}