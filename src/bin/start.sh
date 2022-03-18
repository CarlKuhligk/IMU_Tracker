#!/bin/bash

echo "Start service!"

MYSQL_USER="${MYSQL_USER}"
MYSQL_DATABASE="${MYSQL_DATABASE}"
MYSQL_PASSWORD ="${MYSQL_PASSWORD}"

echo "exit" | sqlplus -L MYSQL_USER/MYSQL_PASSWORD@MYSQL_DATABASE | grep Connected > /dev/null
if [ $? -eq 0 ] 
then
    echo "OK"
    #php /usr/src/wsserver/bin/IMUSocketServer.php

else
    echo "NOT OK"
fi

