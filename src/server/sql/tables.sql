CREATE TABLE `devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `apikey` char(64) NOT NULL COMMENT 'this key is used for regestration',
  `changed` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'last change',
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  `connected` tinyint(1) NOT NULL COMMENT 'connection state',
  `isLoggedIn` tinyint(1) NOT NULL COMMENT 'login state',
  `lastConnection` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'last recived message',
  `employee` varchar(16) NOT NULL COMMENT 'name of employee',
  `pin` char(64) NOT NULL COMMENT 'pin to logout',
  `idleTimeout` int(10) unsigned NOT NULL COMMENT 'in seconds',
  `batteryWarning` tinyint(4) unsigned NOT NULL COMMENT 'in %',
  `connectionTimeout` int(10) unsigned NOT NULL COMMENT 'in seconds',
  `measurementInterval` int(10) unsigned NOT NULL COMMENT 'in milliseconds',
  `accelerationMin` float unsigned NOT NULL COMMENT 'in ?',
  `accelerationMax` float unsigned NOT NULL COMMENT 'in ?',
  `rotationMin` float unsigned NOT NULL COMMENT 'in ?',
  `rotationMax` float unsigned NOT NULL COMMENT 'in ?',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `event_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device` int(11) NOT NULL,
  `event` int(11) NOT NULL,
  `capture_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `weight` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DELIMITER ;;
CREATE DEFINER=`securitymotiontracker`@`%` PROCEDURE `addDevice`(IN `in_employee` CHAR(32),
																IN `in_pin` CHAR(64),
																IN `in_idleTimeout` INT(10) Unsigned,
																IN `in_batteryWarning` TINYINT(4) Unsigned,
																IN `in_connectionTimeout` INT(10) Unsigned,
																IN `in_measurementInterval` INT(10) Unsigned,
																IN `in_accelerationMin` FLOAT Unsigned,
																IN `in_accelerationMax` FLOAT Unsigned,
																IN `in_rotationMin` FLOAT Unsigned,
																IN `in_rotationMax` FLOAT Unsigned,
																OUT `out_id` INT(10) Unsigned,
																OUT `out_apikey` CHAR(64))
BEGIN
	
	IF EXISTS(SELECT devices.id FROM devices ORDER BY devices.id DESC LIMIT 1) THEN
		
		SET @last_device_id = (SELECT devices.id FROM devices ORDER BY devices.id DESC LIMIT 1);
	ELSE
		
		SET @last_device_id = 0;
	END IF;

	
	
	SET @new_device_id = COALESCE (@last_device_id +1,1);
	SET out_id =  @new_device_id;
	SET @new_table_name = CONCAT("device_", @new_device_id,"_log");

	
	SET @new_api_key = (SELECT SHA2(CONCAT(CURRENT_TIMESTAMP(),@new_table_name),256));
	SET out_apikey =  @new_api_key;

	
	SET @sha256_pin = (SELECT SHA2(in_pin ,256));

	
	INSERT INTO devices(id,
						apikey,
						connected,
						isLoggedIn,
						employee,
						pin,
						idleTimeout,
						batteryWarning,
						connectionTimeout,
						measurementInterval,
						accelerationMin,
						accelerationMax,
						rotationMin,
						rotationMax)
	VALUES(@new_device_id,
			@new_api_key,
			0,
			0,
			in_employee,
			@sha256_pin,
			in_idleTimeout,
			in_batteryWarning,
			in_connectionTimeout,
			in_measurementInterval,
			in_accelerationMin,
			in_accelerationMax,
			in_rotationMin,
			in_rotationMax);

	
	SET @table_settings = '(`id` int(11) NOT NULL,`timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(), `acceleration` float NOT NULL, `rotation` float NOT NULL, `temperature` float NOT NULL, `battery` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
 	SET @SQL = CONCAT('CREATE TABLE ',@new_table_name, @table_settings);
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
    
	SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' ADD PRIMARY KEY (id);');
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
	
	SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' MODIFY id int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;');
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
	COMMIT;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`securitymotiontracker`@`%` PROCEDURE `removeDevice`(IN in_id INT Unsigned)
BEGIN
	DELETE FROM `devices` WHERE id=in_id ;
	DELETE FROM event_log  WHERE device=in_id ;
	SET @table_name = CONCAT("device_", in_id,"_log");
	SET @SQL = CONCAT('DROP TABLE IF EXISTS ',@table_name, ';');
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
	COMMIT;

END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`securitymotiontracker`@`%` PROCEDURE `removeObsoleteData`(IN `days` INT(11))
    COMMENT 'deletes data from all device logs older than the specified time'
BEGIN

	DECLARE temp_tablename CHAR(32);

	DECLARE not_done INT DEFAULT TRUE;

	DECLARE db_cursor CURSOR FOR SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE engine = 'innodb' AND table_schema = 'security_motion_tracker' AND table_name LIKE 'device_%%_log%';

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET not_done = FALSE;
	OPEN db_cursor;
	WHILE not_done DO

    	FETCH db_cursor INTO temp_tablename; 

    	IF(temp_tablename IS NOT NULL) THEN

 	    	SET @SQL = CONCAT('DELETE FROM ',temp_tablename, ' WHERE TIMESTAMPDIFF(DAY, timestamp, CURRENT_TIMESTAMP) >= ',days,';');

	    	PREPARE stmt FROM @SQL;

	    	EXECUTE stmt;

	    	DEALLOCATE PREPARE stmt;

	    END IF;

	END WHILE;

COMMIT;

CLOSE db_cursor;

END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`securitymotiontracker`@`%` PROCEDURE `resetTable`(IN `tableName` VARCHAR(32))
BEGIN

  SET @SQL = CONCAT('DELETE FROM ', tableName);

  PREPARE stmt FROM @SQL;

  EXECUTE stmt;

    

	SET @SQL = CONCAT('ALTER TABLE ', tableName, ' AUTO_INCREMENT = 1');

  PREPARE stmt FROM @SQL;

  EXECUTE stmt;

  

  DEALLOCATE PREPARE stmt;

END ;;
DELIMITER ;

