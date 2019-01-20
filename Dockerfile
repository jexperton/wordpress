FROM jexperton/php:7.2-apache

ARG DOMAIN
ARG DB_HOST
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
ARG MEMORY_LIMIT
ARG MAX_EXECUTION_TIME
ARG UPLOAD_MAX_FILESIZE
ARG DISPLAY_ERRORS

RUN apk add --update --no-cache apache2-ssl \
    php7-opcache@php \
    php7-memcached@php \
    mysql \
    mysql-client \
    zlib

COPY ssl.conf /etc/apache2/conf.d/ssl.conf
COPY run.sh /run.sh

RUN chown -R www-data:www-data /etc/phpmyadmin && \ 
    mkdir -p /run/mysqld && \
    chmod +x /run.sh

EXPOSE 443

CMD ["/run.sh"]