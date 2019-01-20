#!/bin/sh
wget -q -O /etc/ssl/fullchain.pem https://s3-us-west-2.amazonaws.com/minimal-media/minimal-cli/certs/fullchain1.pem
wget -q -O /etc/ssl/privkey.pem https://s3-us-west-2.amazonaws.com/minimal-media/minimal-cli/certs/privkey1.pem

sed -i "s/^ServerName .*/ServerName ${DOMAIN}/gI" /etc/apache2/httpd.conf
sed -i "s/^user = .*/user = www-data/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/^group = .*/group = www-data/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/^memory_limit = .*/memory_limit = ${MEMORY_LIMIT:-128M}/g" /etc/php7/php.ini
sed -i "s/^max_execution_time = .*/max_execution_time = ${MAX_EXECUTION_TIME:-30}/g" /etc/php7/php.ini
sed -i "s/^upload_max_filesize = .*/upload_max_filesize = ${UPLOAD_MAX_FILESIZE:-16M}/g" /etc/php7/php.ini
sed -i "s/^post_max_size = .*/post_max_size = ${UPLOAD_MAX_FILESIZE:-16M}/g" /etc/php7/php.ini
sed -i "s/^display_errors = .*/display_errors = ${DISPLAY_ERRORS:-Off}/g" /etc/php7/php.ini
sed -i "s/^display_startup_errors = .*/display_startup_errors = ${DISPLAY_ERRORS:-Off}/g" /etc/php7/php.ini

echo -e "\
env[DOMAIN] = ${DOMAIN}\n\
env[DB_HOST] = ${DB_HOST}\n\
env[DB_NAME] = ${DB_NAME}\n\
env[DB_USER] = ${DB_USER}\n\
env[DB_PASSWORD] = ${DB_PASSWORD}" >> /etc/php7/php-fpm.d/www.conf

if [ "${DB_HOST}" == "127.0.0.1:3306" ]; then 
    echo -e "\
    CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;\n\
    CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';\n\
    GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';\n\
    FLUSH PRIVILEGES;" > /initdb.sql
    mysql_install_db --user=root > /dev/null
    /usr/bin/mysqld --bind-address=0.0.0.0 --user=root --verbose=0 --init-file=/initdb.sql 2> /dev/null &
fi

/usr/sbin/php-fpm7 > /dev/null
/usr/sbin/httpd
tail -f /var/log/apache2/access.log
