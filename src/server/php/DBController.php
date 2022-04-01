<?php
include_once 'Console.php';

class DBController
{

    private $mariadbClient;
    private $host;
    private $user;
    private $password;
    private $dbname;
    private $connectionAttempt;
    private $nextAttemptDelay = 3;
    private $maxConnectionAttempts = 20;

    // initiate database connection with given parameters
    function __construct($host, $user, $password, $dbname)
    {
        $this->host = $host;
        $this->user = $user;
        $this->password = $password;
        $this->dbname = $dbname;
    }


    private function checkIfRequiredDatabaseTableIsMissing()
    {
        $result = $this->dbQuery("SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '{$this->dbname}' AND TABLE_NAME = 'devices';");
        $row = $result->fetch_row();
        if (empty($row)) {
            return true;
        }
        return false;
    }

    public function initializingDatabaseIfNecessary()
    {
        console_log("Initialize database check.\n");
        if ($this->checkIfRequiredDatabaseTableIsMissing()) {
            $this->importSQLFileToDatabase(getenv("MYSQL_PATH"));
        }
    }

    public function importSQLFileToDatabase($filepath)
    {
        console_log("Importing database from '{$filepath}'\n");
        $output = shell_exec("mysql -h {$this->host} -u{$this->user} -p{$this->password} {$this->dbname} < {$filepath}"); // requires mariadb-client or default-mysql-client
        console_log($output . "\n");
        console_log("Tables imported successfully\n");
    }


    private function tryConnection()
    {
        try {
            $this->mariadbClient = new mysqli($this->host, $this->user, $this->password, $this->dbname);
        } catch (Exception $e) {
            console_log(" -> {$e->getMessage()} \n");
            return false;
        }
        return true;
    }

    public function connect()
    {
        $this->connectionAttempt = 0;

        while ($this->connectionAttempt <= $this->maxConnectionAttempts) {
            console_log("Connecting to {$this->dbname}\n");
            if ($this->tryConnection()) {
                console_log("-> Connection successfully!\n");
                $this->initializingDatabaseIfNecessary();
                return true;
            } else {
                $this->connectionAttempt++;
                console_log("--> Retry {$this->connectionAttempt} in {$this->nextAttemptDelay} seconds.\n");
                sleep($this->nextAttemptDelay);
            }
        }
        console_log("Maximum connection attempts ({$this->maxConnectionAttempts}) exceeded!\n");
        return false;
    }

    function __destruct()
    {
        unset($this->mariadbClient);
    }

    private function dbQuery($sql)
    {
        if (isset($sql)) {
            return $this->mariadbClient->query($sql);
        }
        return null;
    }

    private function dbRequest($sql)
    {
        if (isset($sql)) {
            $result = $this->mariadbClient->query($sql);
            if ($result === false) {
                console_log("DB Request -> {$this->mariadbClient->error}\n");
            }
            return true;
        }
        return false;
    }

    public function validateApiKey($apiKey)
    {
        $result = $this->dbQuery("SELECT id, staff_id FROM devices WHERE apikey = '$apiKey';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $device = (object)[
                'id' => $row[0],
                'stuffId' => $row[1],

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
                    'stuffId' => $row[0],
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
                'staffId' => $row[1]
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

    public function writeTrackingData($tableName, $data)
    {
        $acceleration = $data->a;
        $rotation = $data->r;
        $temperature = $data->tp;
        $battery = $data->b;

        return $this->dbRequest("INSERT $tableName (acceleration, rotation, temperature, battery) VALUES ($acceleration, $rotation,$temperature,$battery);");
    }

    public function loadDevices()
    {
        $result = $this->dbQuery("SELECT id, staff_id FROM devices;");
        if (isset($result)) {
            $resultCount = $result->num_rows;
            $deviceList = array();

            for ($i = 0; $i < $resultCount; $i++) {
                $channelRaw =  $result->fetch_row();
                $device = (object)[
                    'id' => $channelRaw[0],
                    'staffId' => $channelRaw[1]
                ];
                array_push($deviceList, $device);
            }
            return $deviceList;
        }
        return NULL;
    }

    public function resetDevices()
    {
        $this->dbRequest("UPDATE devices SET online=0 WHERE 1;");
    }
}
