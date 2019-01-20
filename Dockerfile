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

RUN echo -e "\
    env[DOMAIN] = \$DOMAIN\n\
    env[DB_HOST] = \$DB_HOST\n\
    env[DB_NAME] = \$DB_NAME\n\
    env[DB_USER] = \$DB_USER\n\
    env[DB_PASSWORD] = \$DB_PASSWORD" >> /etc/php7/php-fpm.d/www.conf && \
    # set the 'ServerName' directive globally 
    sed -i 's/^ServerName .*/ServerName \$DOMAIN/gI' /etc/apache2/httpd.conf && \
    # SSL configuration
    echo -e '\
    LoadModule ssl_module /usr/lib/apache2/mod_ssl.so\n\
    Listen 443\n\
    SSLProtocol all -SSLv2 -SSLv3\n\
    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA\n\
    SSLHonorCipherOrder on\n\
    #SSLSessionTickets off\n\
    #SSLUseStapling on\n\
    #SSLStaplingCache "shmcb:logs/stapling-cache(150000)"\n\
    #SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"\n\
    #Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains"\n\
    #Header always set X-Frame-Options DENY\n\
    #Header always set X-Content-Type-Options nosniff\n\
    <Virtualhost *:80>\n\
        Redirect / https://%{HTTP_HOST}%{REQUEST_URI}\n\   
    </Virtualhost>\n\
    <Virtualhost _default_:443>\n\
        SSLEngine on\n\
        SSLCertificateFile /etc/ssl/fullchain.pem\n\
        SSLCertificateKeyFile /etc/ssl/privkey.pem\n\
        #<FilesMatch "\.(cgi|shtml|phtml|php)$">\n\
        #    SSLOptions +StdEnvVars\n\
        #</FilesMatch>\n\
    </Virtualhost> \
    ' > /etc/apache2/conf.d/ssl.conf

RUN echo -e "#!/bin/sh\n\
    wget -O /etc/ssl/fullchain.pem https://s3-us-west-2.amazonaws.com/minimal-media/minimal-cli/certs/fullchain1.pem\n\
    wget -O /etc/ssl/privkey.pem https://s3-us-west-2.amazonaws.com/minimal-media/minimal-cli/certs/privkey1.pem\n\
    sed -i \"s/^user = .*/user = www-data/g\" /etc/php7/php-fpm.d/www.conf\n\
    sed -i \"s/^group = .*/group = www-data/g\" /etc/php7/php-fpm.d/www.conf\n\
    sed -i \"s/^memory_limit = .*/memory_limit = \${MEMORY_LIMIT:-128M}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^max_execution_time = .*/max_execution_time = \${MAX_EXECUTION_TIME:-30}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^upload_max_filesize = .*/upload_max_filesize = \${UPLOAD_MAX_FILESIZE:-16M}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^post_max_size = .*/post_max_size = \${UPLOAD_MAX_FILESIZE:-16M}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^display_errors = .*/display_errors = \${DISPLAY_ERRORS:-Off}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^display_startup_errors = .*/display_startup_errors = \${DISPLAY_ERRORS:-Off}/g\" /etc/php7/php.ini\n\
    /usr/sbin/php-fpm7\n\
    /usr/sbin/httpd\n\
    tail -f /var/log/apache2/access.log\
    " > /run.sh

EXPOSE 443

CMD ["/run.sh"]