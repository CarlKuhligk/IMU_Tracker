<?php

$servername = "localhost";
$dbname = "imutracker";
$username = "imuAPI";
$password = "Cs.![qPtTOAVxs].";

$tableRowCount = 10000;

// api keys stored in the database
$api_key_value = "kzNABRcbVBQghFDC";

$api_key = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $api_key = htmlspecialchars($_POST["api_key"]);
    if($api_key == $api_key_value) {
        
        // Create connection
        $conn = new mysqli($servername, $username, $password, $dbname);
        // Check connection
        if ($conn->connect_error) {
            die("Connection failed: " . $conn->connect_error);
        } 
        $sql = "CALL resetTable()";

        if ($conn->query($sql) === TRUE) {
            echo "Table has been successfully reseted <br>\n";
        } 
        else {
            echo "Error: " . $sql . "<br>" . $conn->error;
        }

        $sql = "CALL createRows($tableRowCount)";

        if ($conn->query($sql) === TRUE) {
            echo "Table has been successfully initialised <br>\n";
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