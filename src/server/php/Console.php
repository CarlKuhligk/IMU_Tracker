<?php
// can enabled and disabled by overwriting environment variable CONSOLE_OUTPUT via docker
// CONSOLE_OUTPUT=0 -> disables the console output
// CONSOLE_OUTPUT=1 -> enables the console output
function consoleLog($message)
{
    if (getenv("CONSOLE_OUTPUT")) {
        $now = new DateTime(strtotime(time()), new DateTimeZone(getenv("TZ")));
        echo  "{$now->format('Y-m-d H:i:s')} :  {$message} \n";
    }
}
