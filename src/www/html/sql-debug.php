<?php
echo "Hello debug";

$host = getenv("MYSQL_HOST");
$user = getenv("MYSQL_USER");
$password = getenv("MYSQL_PASSWORD");
$database = getenv("MYSQL_DATABASE");

echo "Host: " . $host . "<br>";
echo "User: " . $user . "<br>";
echo "Password: " . $password . "<br>";
echo "Database: " . $database . "<br>";


$db = new mysqli($host, $user, $password, $dbname);
if ($db->connect_error) {
    echo "Connection to " . $dbname . " failed: " . $db->connect_error;
} else {
    echo "Connected";
}
