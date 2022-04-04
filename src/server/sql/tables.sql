-- MySQL dump 10.13  Distrib 5.5.62, for Win64 (AMD64)
--
-- Host: localhost    Database: security_motion_tracker
-- ------------------------------------------------------
-- Server version	5.5.5-10.7.3-MariaDB-1:10.7.3+maria~focal

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `devices`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `devices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `apikey` char(64) NOT NULL COMMENT 'this key is used for regestration',
  `changed` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'last change',
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  `connected` tinyint(1) NOT NULL COMMENT 'connection state',
  `isLoggedIn` tinyint(1) NOT NULL COMMENT 'login state',
  `lastConnection` timestamp NOT NULL COMMENT 'last recived message',
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devices`
--

LOCK TABLES `devices` WRITE;
/*!40000 ALTER TABLE `devices` DISABLE KEYS */;
/*!40000 ALTER TABLE `devices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_log`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `device` int(11) NOT NULL,
  `event` int(11) NOT NULL,
  `capture_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_log`
--

LOCK TABLES `event_log` WRITE;
/*!40000 ALTER TABLE `event_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `weight` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'security_motion_tracker'
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`securitymotiontracker`@`%` PROCEDURE `addDevice`(IN `in_employee` VARCHAR(16),
																IN `in_pin` VARCHAR(8),
																IN `in_idleTimeout` INT(10) Unsigned,
																IN `in_batteryWarning` TINYINT(4) Unsigned,
																IN `in_connectionTimeout` INT(10) Unsigned,
																IN `in_measurementInterval` INT(10) Unsigned,
																IN `in_accelerationMin` FLOAT Unsigned,
																IN `in_accelerationMax` FLOAT Unsigned,
																IN `in_rotationMin` FLOAT Unsigned,
																IN `in_rotationMax` FLOAT Unsigned,
																OUT `out_apikey` CHAR(64))
BEGIN
	
	IF EXISTS(SELECT devices.id FROM devices ORDER BY devices.id DESC LIMIT 1) THEN
		-- use last device id
		SET @last_device_id = (SELECT devices.id FROM devices ORDER BY devices.id DESC LIMIT 1);
	ELSE
		-- use device id 0 if table is empty
		SET @last_device_id = 0;
	END IF;

	
	-- define new device id and log table name
	SET @new_device_id = COALESCE (@last_device_id +1,1);
	SET @new_table_name = CONCAT("device_", @new_device_id,"_log");

	-- generate api key based on tablename and timestamp
	SET @new_api_key = (SELECT SHA2(CONCAT(CURRENT_TIMESTAMP(),@new_table_name),256));
	SET out_apikey =  @new_api_key;

	-- pin
	SET @sha256_pin = (SELECT SHA2(in_pin ,256));

	-- add new device
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

	-- prepare device log table settings
	SET @table_settings = '(`id` int(11) NOT NULL,`timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(), `acceleration` float NOT NULL, `rotation` float NOT NULL, `temperature` float NOT NULL, `battery` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
 
	-- create new device log table
	SET @SQL = CONCAT('CREATE TABLE ',@new_table_name, @table_settings);
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
    -- add primary key
	SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' ADD PRIMARY KEY (id);');
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
	-- add autoincrement
	SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' MODIFY id int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;');
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
  
	DEALLOCATE PREPARE stmt;
	COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`securitymotiontracker`@`%` PROCEDURE `delete_device_data`(IN `days` INT(11))
    COMMENT 'deletes data from all device logs older than the specified time'
BEGIN

	DECLARE temp_tablename CHAR(32);

	DECLARE not_done INT DEFAULT TRUE;

	DECLARE db_cursor CURSOR FOR SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE engine = 'innodb' AND table_schema = 'security_motion_tracker' AND table_name LIKE 'device_%%_log%';

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET not_done = FALSE;

	OPEN db_cursor;



	WHILE not_done DO

    	FETCH db_cursor INTO temp_tablename;    

    	SET @SQL = CONCAT('DELETE FROM ',temp_tablename, ' WHERE TIMESTAMPDIFF(DAY, timestamp, CURRENT_TIMESTAMP) >= ',days,';');

    	PREPARE stmt FROM @SQL;

    	EXECUTE stmt;

	END WHILE;



DEALLOCATE PREPARE stmt;

COMMIT;

CLOSE db_cursor;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
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
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-04-02 15:39:32
