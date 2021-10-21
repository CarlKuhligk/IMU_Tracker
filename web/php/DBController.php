<?php

class DBController
{

    private $dbConnection;
    private $servername;
    private $username;
    private $password;
    private $dbname;

    // initiate databse connaction with given parameters
    function __construct($servername, $username, $password, $dbname)
    {
        $this->servername = $servername;
        $this->username = $username;
        $this->password = $password;
        $this->dbname = $dbname;
    }

    public function connect()
    {
        // creat db connection
        $this->dbConnection = new mysqli($this->servername, $this->username, $this->password, $this->dbname);
        if ($this->dbConnection->connect_error) {
            echo "Connection to " . $this->dbname . " failed: " . $this->dbConnection->connect_error;
        } else {
            return true;
        }
    }

    function __destruct()
    {
        unset($this->dbConnection);
    }

    private function dbQuery($sql)
    {
        if (isset($sql)) {
            return $this->dbConnection->query($sql);
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

    public function validateApiKey($apiKey)
    {
        $result = $this->dbQuery("SELECT id, name FROM channels WHERE api_key = '$apiKey';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $channel = (object)[
                'id' => $row[0],
                'name' => $row[1]
            ];
            return $channel;
        }
        return false;
    }

    public function validateChannelId($id)
    {
        $result = $this->dbQuery("SELECT id, name FROM channels WHERE id = '$id';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $channel = (object)[
                'id' => $row[0],
                'name' => $row[1]
            ];
            return $channel;
        }
        return false;
    }

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
        $row = $result->fetch_row();
        $row = filter_var($row['online'], FILTER_VALIDATE_BOOLEAN);
        return $row;
    }

    public function setChannelStatus($id, $status)
    {
        return $this->dbRequest("UPDATE channels SET status='$status' WHERE id='$id';");
    }

    public function setSubscriberCount($id, $count)
    {
        return $this->dbRequest("UPDATE channels SET reciver='$count' WHERE id = '$id';");
    }

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

    public function loadChannels()
    {
        $result = $this->dbQuery("SELECT id, name, status FROM channels;");
        $resultCount = $result->num_rows;
        $channels = array();

        for ($i = 0; $i < $resultCount; $i++) {
            $channelRaw =  $result->fetch_row();
            $channel = (object)[
                'id' => $channelRaw[0],
                'name' => $channelRaw[1],
                'state' => $channelRaw[2],
            ];
            array_push($channels, $channel);
        }
        return $channels;
    }

    public function resetChannels()
    {
        $this->dbRequest("UPDATE channels SET online=0,reciver=0 WHERE 1;");
    }
}
