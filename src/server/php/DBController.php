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
        $row = $result->fetch();
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
        if ($output)
            consoleLog("Import result: {$output}");
        else
            consoleLog("Tables imported successfully");
    }


    private function tryToConnect()
    {
        try {
            $this->mariadbClient = new PDO("mysql:host=$this->host;dbname=$this->dbname", $this->user, $this->password);
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
        $result = $this->dbQuery("SELECT id,
                                        connected,
                                        isLoggedIn,
                                        lastConnection,
                                        employee,
                                        idleTimeout,
                                        batteryWarning,
                                        connectionTimeout,
                                        measurementInterval,
                                        accelerationMin,
                                        accelerationMax,
                                        rotationMin,
                                        rotationMax 
                                        FROM devices WHERE id = '$id';");
        $row = $result->fetch();
        if (isset($row)) {
            $device = (object)[
                'id' => $row[0],
                'connected' => $row[1],
                'isLoggedIn' => $row[2],
                'lastConnection' => $row[3],
                'employee' => $row[4],
                'settings' => (object)[
                    'idleTimeout' => $row[5],
                    'batteryWarning' => $row[6],
                    'connectionTimeout' => $row[7],
                    'measurementInterval' => $row[8],
                    'accelerationMin' => $row[9],
                    'accelerationMax' => $row[10],
                    'rotationMin' => $row[11],
                    'rotationMax' => $row[12],
                ]
            ];
            return $device;
        }
        return false;
    }

    public function updateDeviceSettings($id, $newSettings)
    {
        $it = $newSettings->it;
        $b = $newSettings->b;
        $c = $newSettings->c;
        $m = $newSettings->m;
        $ai = $newSettings->ai;
        $a = $newSettings->a;
        $ri = $newSettings->ri;
        $r = $newSettings->r;
        $this->dbRequest("UPDATE devices SET idleTimeout = $it, batteryWarning = $b, connectionTimeout = $c, measurementInterval = $m, accelerationMin = $ai, accelerationMax = $a, rotationMin = $ri, rotationMax = $r WHERE id='$id';");
    }

    public function validateKey($apikey)
    {
        $result = $this->dbQuery("SELECT id FROM devices WHERE apikey = '$apikey';");
        $row = $result->fetch();
        if (isset($row)) {
            $deviceID = $row[0];
            return $deviceID;
        }
        return false;
    }

    public function validatePin($pin, $requestingDevice)
    {
        $result = $this->dbQuery("SELECT isLoggedIn FROM devices WHERE id = '$requestingDevice->id' AND pin = '$pin';");
        if (isset($result)) {
            $row = $result->fetch();
            if (isset($row)) {
                return true;
            }
        }
        return false;
    }

    public function validateDeviceId($id)
    {
        $result = $this->dbQuery("SELECT id FROM devices WHERE id = '$id';");
        $row = $result->fetch();
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
            $this->dbRequest("UPDATE devices SET isLoggedIn=0 WHERE id='$id';");
        } else {
            $this->dbRequest("UPDATE devices SET isLoggedIn=1 WHERE id='$id';");
        }
    }

    public function getDeviceIsConnected($id)
    {
        $result = $this->dbQuery("SELECT connected FROM devices WHERE id='$id';");
        $row = $result->fetch();
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
            $resultCount = $result->rowCount();
            $deviceList = array();

            for ($i = 0; $i < $resultCount; $i++) {
                $row =  $result->fetch();
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


    public function setLastConnectionTime($id, $time)
    {
        $this->dbRequest("UPDATE devices SET lastConnection='{$time->format('Y-m-d H:i:s')}' WHERE id='$id';");
    }

    public function getLastConnectionTime($id)
    {
        $timeString = $this->dbRequest("SELECT lastConnection FROM devices WHERE id='$id';");
        return new DateTime($timeString, new DateTimeZone($this->settings->timezone));
    }

    public function createDevice($initializationData)
    {
        $call = $this->mariadbClient->prepare('CALL addDevice(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @id, @apikey)');
        $call->bindParam(1, $initializationData->e, PDO::PARAM_STR);
        $call->bindParam(2, $initializationData->p, PDO::PARAM_STR);
        $call->bindParam(3, $initializationData->it);
        $call->bindParam(4, $initializationData->b);
        $call->bindParam(5, $initializationData->c);
        $call->bindParam(6, $initializationData->m);
        $call->bindParam(7, $initializationData->ai);
        $call->bindParam(8, $initializationData->a);
        $call->bindParam(9, $initializationData->ri);
        $call->bindParam(10, $initializationData->r);

        $call->execute();
        $select = $this->mariadbClient->query('SELECT @id, @apikey');
        $sqlResult = $select->fetch(PDO::FETCH_ASSOC);
        $result     = (object)[
            "id" => $sqlResult['@id'],
            "apikey" => $sqlResult['@apikey']
        ];
        return $result;
    }
}
