FROM php:apache

# CREAETE NEW USER 'www' #
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

###############################################
# INSTALL RATCHET + COMPOSER + MARIADB CLIENT #
###############################################
RUN apt-get update && apt-get dist-upgrade && apt-get install -y \
    zlib1g-dev \
    libzip-dev \
    unzip \
    mariadb-client

RUN docker-php-ext-install zip
RUN docker-php-ext-install mysqli pdo pdo_mysql
RUN docker-php-ext-enable mysqli
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

RUN apt autoclean

####################################
# C O P Y  P R O J E C T F I L E S #
####################################
RUN mkdir /usr/app
RUN mkdir /usr/app/bin
RUN mkdir /usr/app/php
RUN mkdir /usr/app/sql

# COMPOSER FILE #
COPY ./composer.json /usr/app/
# WEBSOCKETSERVER #
COPY ./bin/ /usr/app/bin/
COPY ./php/ /usr/app/php/
# DATABASE TEMPLATE #
COPY ./sql/ /usr/app/sql/
RUN chmod a+rwx -R /usr/app
# WEBCONTENT #
COPY ./www/html/ /var/www/html/
RUN chmod a+rwx -R /var/www/html
# ANDROID APP #
#COPY ../../app/web/ /usr/app/bin/
#RUN chmod a+rwx -R /var/www/html


##########################################
# E N V I R O M E N T  V A R I A B L E S #
##########################################
# DATABASE #
ENV MYSQL_HOST "localhost"
ENV MYSQL_DATABASE "security_motion_tracker"
ENV MYSQL_USER "mrdatabase"
ENV MYSQL_PASSWORD "mydatabase"
# DATABASE INITIALISATION FILE#
ENV MYSQL_PATH "/usr/app/sql/tables.sql"
# CONSOLE LOGGING #
ENV CONSOLE_OUTPUT 1

#######################
# W E B C O N T E N T #
#######################
EXPOSE 80

#################################
# W E B S O C K E T S E R V E R #
#################################
EXPOSE 8080
WORKDIR /usr/app
USER www
RUN composer update
CMD service apache2 start && php ./bin/WebsocketServer.php -F
