BEGIN
	#get last device id and creat new unique tablename
    SET @last_device_id = (SELECT devices.id FROM devices ORDER BY devices.id DESC LIMIT 1);
    
    SET @new_device_id = COALESCE (@last_device_id +1,1);
    SET @new_table_name = CONCAT("device_", @new_device_id,"_log");
    
    #generate api key
    SET @new_api_key = (SELECT SHA2(CONCAT(CURRENT_TIMESTAMP(),@new_table_name),256));
	INSERT INTO devices(devices.id, devices.api_key) VALUES(@new_device_id, @new_api_key);
        
    SET @table_settings = '(`capture_id` int(11) NOT NULL,`timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),       `accX` float NOT NULL,      `accY` float NOT NULL,\r\n        `accZ` float NOT NULL,      `gyrX` float NOT NULL,      `gyrY` float NOT NULL,      `gyrZ` float NOT NULL,       `temp` float NOT NULL, `battery` int(11) NOT NULL, `status` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
    
    #creat new table
    SET @SQL = CONCAT('CREATE TABLE ',@new_table_name, @table_settings);
    PREPARE stmt FROM @SQL;
    EXECUTE stmt;
    
    #setup primary key and autoincrement
    SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' ADD PRIMARY KEY (capture_id);');
	PREPARE stmt FROM @SQL;
    EXECUTE stmt;

	SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' MODIFY capture_id int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;');
	PREPARE stmt FROM @SQL;
    EXECUTE stmt;
    
    # insert new row in device settings
    INSERT INTO device_settings (device_id, acc_min, acc_max, gyr_min, gyr_max,  battery_warning, timeout, sense_freq)SELECT * FROM (SELECT devices.id AS device_id FROM devices ORDER BY id DESC LIMIT 1) AS DEVICEID,(SELECT acc_min, acc_max, gyr_min, gyr_max,  battery_warning, timeout, sense_freq FROM device_settings WHERE id = 0 LIMIT 1) AS DEFAULTSETTINGS;

 
   

    
    DEALLOCATE PREPARE stmt;
    COMMIT;
END