-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: mariadb
-- Erstellungszeit: 18. Mrz 2022 um 23:49
-- Server-Version: 10.7.3-MariaDB-1:10.7.3+maria~focal
-- PHP-Version: 8.0.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Datenbank: `security_motion_tracker`
--
-- CREATE DATABASE IF NOT EXISTS `security_motion_tracker` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `security_motion_tracker`;

DELIMITER $$
--
-- Prozeduren
--
CREATE PROCEDURE `addDevice` ()   BEGIN
	
  SET @last_device_id = (SELECT devices.id FROM devices ORDER BY devices.id DESC LIMIT 1);
  
  SET @new_device_id = COALESCE (@last_device_id +1,1);
  SET @new_table_name = CONCAT("device_", @new_device_id,"_log");
  
  
  SET @new_api_key = (SELECT SHA2(CONCAT(CURRENT_TIMESTAMP(),@new_table_name),256));
	INSERT INTO devices(devices.id, devices.apikey, devices.staff_id, devices.online) VALUES(@new_device_id, @new_api_key, 0, 0);
    
  SET @table_settings = '(`capture_id` int(11) NOT NULL,`timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(), `acceleration` float NOT NULL, `rotation` float NOT NULL, `temperature` float NOT NULL, `battery` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
  
  
  SET @SQL = CONCAT('CREATE TABLE ',@new_table_name, @table_settings);
  PREPARE stmt FROM @SQL;
  EXECUTE stmt;
  
  
  SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' ADD PRIMARY KEY (capture_id);');
	PREPARE stmt FROM @SQL;
  EXECUTE stmt;

	SET @SQL = CONCAT('ALTER TABLE ',@new_table_name, ' MODIFY capture_id int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;');
	PREPARE stmt FROM @SQL;
  EXECUTE stmt;
  
  
  INSERT INTO device_settings (device_id, idle_time,  battery_warning, timeout, sense_freq)SELECT * FROM (SELECT devices.id AS device_id FROM devices ORDER BY id DESC LIMIT 1) AS DEVICEID,(SELECT idle_time,  battery_warning, timeout, sense_freq FROM device_settings WHERE device_id = 1 LIMIT 1) AS DEFAULTSETTINGS;
  
  DEALLOCATE PREPARE stmt;
  COMMIT;
END$$

CREATE PROCEDURE `delete_device_data` (IN `days` INT(11))   BEGIN
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

END$$

CREATE PROCEDURE `resetTable` (IN `tableName` VARCHAR(32))   BEGIN
  SET @SQL = CONCAT('DELETE FROM ', tableName);
  PREPARE stmt FROM @SQL;
  EXECUTE stmt;
    
	SET @SQL = CONCAT('ALTER TABLE ', tableName, ' AUTO_INCREMENT = 1');
  PREPARE stmt FROM @SQL;
  EXECUTE stmt;
  
  DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `devices`
--

CREATE TABLE `devices` (
  `id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL COMMENT 'contains the ip of the staff',
  `apikey` char(64) NOT NULL COMMENT 'this key is used for regestration',
  `changed` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'last change',
  `created` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'created',
  `online` tinyint(1) NOT NULL COMMENT 'online status'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `devices`
--

INSERT INTO `devices` (`id`, `staff_id`, `apikey`, `changed`, `created`, `online`) VALUES
(1, 0, '2d186bb64f3a0c56f72c75f05dca98935b893136c43245a2068f4314cef84935', '2022-03-18 23:39:13', '2022-03-18 23:32:24', 0);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `device_1_log`
--

CREATE TABLE `device_1_log` (
  `capture_id` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `acceleration` float NOT NULL,
  `rotation` float NOT NULL,
  `temperature` float NOT NULL,
  `battery` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `device_settings`
--

CREATE TABLE `device_settings` (
  `device_id` int(11) NOT NULL,
  `idle_time` float NOT NULL,
  `battery_warning` int(11) NOT NULL,
  `timeout` int(11) NOT NULL,
  `sense_freq` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `device_settings`
--

INSERT INTO `device_settings` (`device_id`, `idle_time`, `battery_warning`, `timeout`, `sense_freq`) VALUES
(1, 0, 0, 0, 0),
(2, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `events`
--

CREATE TABLE `events` (
  `id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `event_log`
--

CREATE TABLE `event_log` (
  `id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  `trigger_capture_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `staff`
--

CREATE TABLE `staff` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL COMMENT 'fist name',
  `pin` varchar(256) NOT NULL COMMENT 'logout pin'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `staff`
--

INSERT INTO `staff` (`id`, `name`, `pin`) VALUES
(0, 'template', '00000');

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`id`);

--
-- Indizes für die Tabelle `device_1_log`
--
ALTER TABLE `device_1_log`
  ADD PRIMARY KEY (`capture_id`);

--
-- Indizes für die Tabelle `device_settings`
--
ALTER TABLE `device_settings`
  ADD PRIMARY KEY (`device_id`);

--
-- Indizes für die Tabelle `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`);

--
-- Indizes für die Tabelle `event_log`
--
ALTER TABLE `event_log`
  ADD PRIMARY KEY (`id`);

--
-- Indizes für die Tabelle `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `devices`
--
ALTER TABLE `devices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT für Tabelle `device_1_log`
--
ALTER TABLE `device_1_log`
  MODIFY `capture_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `events`
--
ALTER TABLE `events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `event_log`
--
ALTER TABLE `event_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT für Tabelle `staff`
--
ALTER TABLE `staff`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;
