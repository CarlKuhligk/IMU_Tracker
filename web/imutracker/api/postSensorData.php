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

// Keep this API Key value to be compatible with the ESP32 code provided in the project page. 
// If you change this value, the ESP32 sketch needs to match
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
        
        $sql = "INSERT INTO measures (accX, accY, accZ, gyrX, gyrY, gyrZ, temp)
        VALUES ('" . $accX . "', '" . $accY . "', '" . $accZ . "', '" . $gyrX . "', '" . $gyrY . "', '" . $gyrZ . "', '" . $temp . "')";
        
        if ($conn->query($sql) === TRUE) {
            echo "New record created successfully";
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