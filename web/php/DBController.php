<?php

class DBController
{

    private $dbConnection;

    // initiate databse connaction with given parameters
    public function __cunstruct()
    {
    }

    public function connect($servername, $username, $password, $dbname)
    {
        // creat db connection
        $this->dbConnection = new mysqli($servername, $username, $password, $dbname);
        if ($this->dbConnection->connect_error) {
            echo "Connection to " . $dbname . " failed: " . $this->dbConnection->connect_error;
        } else {
            return true;
        }
    }

    public function __destruct()
    {
        unset($this->dbConnection);
    }

    private function dbQuery($sql)
    {
        if (isset($sql)) {
            $result = $this->dbConnection->query($sql);
            if (isset($result)) {
                return $result->fetch_array(MYSQLI_ASSOC);
            }
        }
        return null;
    }

    private function dbRequest($sql)
    {
        if (isset($sql)) {
            $result = $this->dbConnection->query($sql);
            if ($result === false) {
                echo "Error: " . $sql . "\n Errormessage: " . $this->dbConnection->error;
            }
            return true;
        }
        return false;
    }

    // validates a apiKey and returns the assigned tablename
    public function validateApiKey($apiKey)
    {
        $row = $this->dbQuery("SELECT id, name FROM channels WHERE api_key = '$apiKey';");
        if (isset($row)) {
            $channel = (object)[
                'id' => $row['id'],
                'name' => $row['name']
            ];
            return $channel;
        }
        return false;
    }

    // validates a channel$channel id and returns the assigned tablename
    public function validateChannelId($id)
    {
        $row = $this->dbQuery("SELECT id, name FROM channels WHERE id = '$id';");
        if (isset($row)) {
            $channel = (object)[
                'id' => $row['id'],
                'name' => $row['name']
            ];
            return $channel;
        }
        return false;
    }

    //
    public function setChannelOnlineState($id, $state)
    {
        if ($state) {
            $this->dbRequest("UPDATE channels SET online=1 WHERE id='$id';");
        } else {
            $this->dbRequest("UPDATE channels SET online=0 WHERE id='$id';");
        }
    }

    public function getChannelOnlineState($id)
    {
        $result = $this->dbQuery("SELECT online FROM channels WHERE id='$id';");
        $result = filter_var($result['online'], FILTER_VALIDATE_BOOLEAN);
        return $result;
    }

    public function setChannelStatus($id, $status)
    {
        return $this->dbRequest("UPDATE channels SET status='$status' WHERE id='$id';");
    }

    public function setSubscriberCount($id, $count)
    {
        return $this->dbRequest("UPDATE channels SET reciver='$count' WHERE id = '$id';");
    }



    // 
    public function writeSensorData($tableName, $data)
    {
        $accX = $data[0];
        $accY = $data[1];
        $accZ = $data[2];
        $gyrX = $data[3];
        $gyrY = $data[4];
        $gyrZ = $data[5];
        $temp = $data[6];
        return $this->dbRequest("UPDATE $tableName SET accX=$accX, accY=$accY, accZ=$accZ, gyrX=$gyrX, gyrY=$gyrY, gyrZ=$gyrZ, temp=$temp WHERE timestamp = (SELECT MIN(timestamp) FROM $tableName) ORDER BY id LIMIT 1;");
    }
}
