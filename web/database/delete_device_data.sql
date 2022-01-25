BEGIN
    DECLARE temp_tablename CHAR(32);
	DECLARE not_done INT DEFAULT TRUE;
    DECLARE db_cursor CURSOR FOR SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE engine = 'innodb' AND table_schema = 'imutracker' AND table_name LIKE 'device_%%_log%';
    
    # condition older 7 Days -> WHERE TIMESTAMPDIFF(DAY, timestamp, CURRENT_TIMESTAMP) >= 7

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

END