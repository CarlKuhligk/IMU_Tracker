<?php
include_once 'Console.php';

class DBController
{

    private $mariadbClient;
    private $host;
    private $user;
    private $password;
    private $dbname;
    private $connectionAttempts;
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
        consoleLog("Initialize database check.");
        if ($this->checkIfRequiredDatabaseTableIsMissing()) {
            $this->importSQLFileToDatabase(getenv("MYSQL_PATH"));
        }
    }

    public function importSQLFileToDatabase($filepath)
    {
        consoleLog("Importing database from '{$filepath}'");
        $output = shell_exec("mysql -h {$this->host} -u{$this->user} -p{$this->password} {$this->dbname} < {$filepath}"); // requires mariadb-client or default-mysql-client
        consoleLog($output . "");
        consoleLog("Tables imported successfully");
    }


    private function tryToConnect()
    {
        try {
            $this->mariadbClient = new mysqli($this->host, $this->user, $this->password, $this->dbname);
        } catch (Exception $e) {
            consoleLog(" -> {$e->getMessage()} ");
            return false;
        }
        return true;
    }

    public function connect()
    {
        $this->connectionAttempts = 0;

        while ($this->connectionAttempts <= $this->maxConnectionAttempts) {
            consoleLog("Connecting to {$this->dbname}");
            if ($this->tryToConnect()) {
                consoleLog("-> Connection successfully!");
                $this->initializingDatabaseIfNecessary();
                return true;
            } else {
                $this->connectionAttempts++;
                consoleLog("--> Connection attempt {$this->connectionAttempts} in {$this->nextAttemptDelay} seconds.");
                sleep($this->nextAttemptDelay);
            }
        }
        consoleLog("Maximum connection attempts ({$this->maxConnectionAttempts}) exceeded!");
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
                consoleLog("DB Request -> {$this->mariadbClient->error}");
            }
            return true;
        }
        return false;
    }

    public function getDevice($id)
    {
        $result = $this->dbQuery("SELECT id, connected, loginState, lastSeen, employee, idleTimeout, batteryWarning, connectionTimeout, measurementInterval FROM devices WHERE id = '$id';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $device = (object)[
                'id' => $row[0],
                'connected' => $row[1],
                'loginState' => $row[2],
                'lastSeen' => $row[3],
                'employee' => $row[4],
                'idleTimeout' => $row[5],
                'batteryWarning' => $row[6],
                'connectionTimeout' => $row[7],
                'measurementInterval' => $row[8]
            ];
            return $device;
        }
        return false;
    }

    public function validateKey($apikey)
    {
        $result = $this->dbQuery("SELECT id FROM devices WHERE apikey = '$apikey';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $deviceID = $row[0];
            return $deviceID;
        }
        return false;
    }

    public function validatePin($pin, $requestingDevice)
    {
        $result = $this->dbQuery("SELECT loginState FROM devices WHERE id = '$requestingDevice->id' AND pin = '$pin';");
        if (isset($result)) {
            $row = $result->fetch_row();
            if (isset($row)) {
                return true;
            }
        }
        return false;
    }

    public function validateDeviceId($id)
    {
        $result = $this->dbQuery("SELECT id FROM devices WHERE id = '$id';");
        $row = $result->fetch_row();
        if (isset($row)) {
            $deviceID = $row[0];
            return $deviceID;
        }
        return false;
    }

    public function setDeviceIsConnected($id, $isConnected)
    {
        if ($isConnected) {
            $this->dbRequest("UPDATE devices SET connected=1 WHERE id='$id';");
        } else {
            $this->dbRequest("UPDATE devices SET connected=0 WHERE id='$id';");
        }
    }

    public function setLoginState($id, $successfullyLoggedOut)
    {
        if ($successfullyLoggedOut) {
            $this->dbRequest("UPDATE devices SET loginState=0 WHERE id='$id';");
        } else {
            $this->dbRequest("UPDATE devices SET loginState=1 WHERE id='$id';");
        }
    }

    public function getDeviceIsConnected($id)
    {
        $result = $this->dbQuery("SELECT connected FROM devices WHERE id='$id';");
        $row = $result->fetch_row();
        $isConnected = filter_var($row['connected'], FILTER_VALIDATE_BOOLEAN);
        return $isConnected;
    }

    public function writeTrackingData($tableName, $data)
    {
        $acceleration = $data->a;
        $rotation = $data->r;
        $temperature = $data->tp;
        $battery = $data->b;

        return $this->dbRequest("INSERT $tableName (acceleration, rotation, temperature, battery) VALUES ($acceleration, $rotation, $temperature, $battery);");
    }

    public function getDevices()
    {
        $result = $this->dbQuery("SELECT id FROM devices;");
        if (isset($result)) {
            $resultCount = $result->num_rows;
            $deviceList = array();

            for ($i = 0; $i < $resultCount; $i++) {
                $row =  $result->fetch_row();
                $deviceID = $row[0];
                $device = $this->getDevice($deviceID);
                array_push($deviceList, $device);
            }
            return $deviceList;
        }
        return NULL;
    }

    public function resetDevicesIsConnected()
    {
        $this->dbRequest("UPDATE devices SET connected=0 WHERE connected=1;");
    }
}
