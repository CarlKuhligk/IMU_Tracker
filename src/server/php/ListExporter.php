<?php
$handle = fopen("ResponseList.php", "r");

$export = fopen("ResponseList.txt", "rw");

if ($handle) {
    while (($line = fgets($handle)) !== false) {
        // process the line read.

    }

    fclose($handle);
    fclose($export);
} else {
    // error opening the file.
}
