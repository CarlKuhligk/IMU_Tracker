

creat virtual host "security-tracker.io"
STEP 1:

edit YOUR DIRECTORY\xampp\apache\conf\extra\httpd-vhosts.conf
add the following:

<VirtualHost *:80>
    DocumentRoot "YOUR DIRECTORY"
    <Directory  "D:YOUR DIRECTORY">
        Require local
        Require ip YOUR IP RANGE (192.168.178)
    </Directory>
    ServerName www.security-tracker.io
</VirtualHost>

STEP 2:
add the host to your system

WINDOWS:
OPEN C:\Windows\System32\drivers\etc\hosts

add the following:

127.0.0.1       localhost
127.0.0.1       security-tracker.io

STEP 3:
add to DNS service
https://www.ip-phone-forum.de/threads/zugriff-via-wlan-und-fritzbox-auf-lokalen-webserver.257501/