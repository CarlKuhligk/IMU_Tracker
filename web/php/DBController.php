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
        $result = $this->dbQuery("SELECT id, staff_id FROM devices WHERE api_key = '$apiKey';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $device = (object)[
                'id' => $row[0],
                'stuff_id' => $row[1],

            ];
            return $device;
        }
        return false;
    }

    public function validatePin($pin, $callingDevice)
    {
        $result = $this->dbQuery("SELECT staff.id, staff.name FROM staff WHERE id = (SELECT devices.staff_id FROM devices WHERE devices.id =" . $callingDevice->id . ") AND staff.pin = '" . $pin . "';");
        if (isset($result)) {
            $row = $result->fetch_row();
            if (isset($row)) {
                $employee = (object)[
                    'id' => $row[0],
                    'name' => $row[1],
                ];
                return $employee;
            }
        }
        return false;
    }

    public function validateChannelId($id)
    {
        $result = $this->dbQuery("SELECT id, staff_id FROM devices WHERE id = '$id';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $device = (object)[
                'id' => $row[0],
                'staff_id' => $row[1]
            ];
            return $device;
        }
        return false;
    }

    public function setDeviceOnlineState($id, $state)
    {
        if ($state) {
            $this->dbRequest("UPDATE devices SET online=1 WHERE id='$id';");
        } else {
            $this->dbRequest("UPDATE devices SET online=0 WHERE id='$id';");
        }
    }

    public function getDeviceOnlineState($id)
    {
        $result = $this->dbQuery("SELECT online FROM devices WHERE id='$id';");
        $row = $result->fetch_row();
        $row = filter_var($row['online'], FILTER_VALIDATE_BOOLEAN);
        return $row;
    }

    public function setDeviceStatus($id, $status)
    {
        return $this->dbRequest("UPDATE devices SET status='$status' WHERE id='$id';");
    }

    public function setObserverCount($id, $count)
    {
        return $this->dbRequest("UPDATE devices SET observer='$count' WHERE id = '$id';");
    }

    public function writeDeviceData($tableName, $data)
    {
        $accX = $data[0];
        $accY = $data[1];
        $accZ = $data[2];
        $gyrX = $data[3];
        $gyrY = $data[4];
        $gyrZ = $data[5];
        $temp = $data[6];
        $batt = $data[7];
        return $this->dbRequest("UPDATE $tableName SET accX=$accX, accY=$accY, accZ=$accZ, gyrX=$gyrX, gyrY=$gyrY, gyrZ=$gyrZ, temp=$temp, battery=$batt WHERE timestamp = (SELECT MIN(timestamp) FROM $tableName) ORDER BY id LIMIT 1;");
    }

    public function loadDevices()
    {
        $result = $this->dbQuery("SELECT id, staff_id FROM devices;");
        if (isset($result)) {
            $resultCount = $result->num_rows;
            $channels = array();

            for ($i = 0; $i < $resultCount; $i++) {
                $channelRaw =  $result->fetch_row();
                $device = (object)[
                    'id' => $channelRaw[0],
                    'name' => $channelRaw[1],
                ];
                array_push($channels, $device);
            }
            return $channels;
        }
        return NULL;
    }

    public function resetDevices()
    {
        $this->dbRequest("UPDATE devices SET online=0 WHERE 1;");
    }
}
