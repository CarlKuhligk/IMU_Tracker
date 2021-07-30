<?php
/*

DONT WORK ANYMORE

*/

include 'DBUser.php';

$api_key = $id = $time = $accX = $accY = $accZ = $gyrX = $gyrY = $gyrZ = $temp = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $api_key = htmlspecialchars($_POST["api_key"]);
    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);
    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    $sql = "SELECT id, name FROM devices WHERE api_key = '$api_key';";
    $result = $conn->query($sql);
    $row = $result -> fetch_array(MYSQLI_ASSOC);

    if ( $row != null) {
        $id = $row['id'];
        $name = $row['name'];
        $tableName = $name."_".$id;

        $accX = htmlspecialchars($_POST["accX"]);
        $accY = htmlspecialchars($_POST["accY"]);
        $accZ = htmlspecialchars($_POST["accZ"]);
        $gyrX = htmlspecialchars($_POST["gyrX"]);
        $gyrY = htmlspecialchars($_POST["gyrY"]);
        $gyrZ = htmlspecialchars($_POST["gyrZ"]);
        $temp = htmlspecialchars($_POST["temp"]);

        // update always the oldest entry
        $sql = "UPDATE $tableName SET accX=$accX, accY=$accY, accZ=$accZ, gyrX=$gyrX, gyrY=$gyrY, gyrZ=$gyrZ, temp=$temp WHERE timestamp = (SELECT MIN(timestamp) FROM $tableName) ORDER BY id LIMIT 1";

        if ($conn->query($sql) === TRUE) {
            echo "Entry updated successfully";
        } 
        else {
            echo "Error: " . $sql . "<br>" . $conn->error;
        }
    } 
    else {
        echo "Wrong API Key provided.";
        echo "Error: " . $sql . "<br>" . $conn->error;
    }
    $conn->close();
}
else {
    echo "No data posted with HTTP POST.";
}
?>