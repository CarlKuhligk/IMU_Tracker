FROM php:7.4.28-apache

RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# INSTALL RATCHET + COMPOSER #
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libzip-dev \
    unzip
RUN docker-php-ext-install zip
RUN docker-php-ext-install mysqli
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

####################################
# C O P Y  P R O J E C T F I L E S #
####################################
RUN mkdir /usr/app
RUN mkdir /usr/app/src
COPY ./ /usr/app/src/
RUN chmod a+rwx -R /usr/app
RUN mv -f /usr/app/src/www/html/* /var/www/html/
RUN chmod 777 /usr/app/src/bin/start.sh

###################
# D A T A B A S E #
###################
ENV MYSQL_HOST = "localhost"
ENV MYSQL_DATABASE = "helloworld"
ENV MYSQL_USER = "mrdatabase"
ENV MYSQL_PASSWORD = "mydatabase"

#######################
# W E B C O N T E N T #
#######################
EXPOSE 80

#################################
# W E B S O C K E T S E R V E R #
#################################
EXPOSE 8080
WORKDIR /usr/app/src
USER www
RUN composer update
CMD [ "php", "./bin/IMUSocketServer.php" ]
