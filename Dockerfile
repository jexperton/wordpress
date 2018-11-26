FROM jexperton/php:7.2-apache

ARG MEMORY_LIMIT
ARG MAX_EXECUTION_TIME
ARG UPLOAD_MAX_FILESIZE
ARG DISPLAY_ERRORS

RUN apk add --update --no-cache apache2-ssl \
    memcached \
    php7-opcache@php \
    php7-memcached@php

RUN echo -e "\
    env[DB_HOST] = \$DB_HOST\n\
    env[DB_NAME] = \$DB_NAME\n\
    env[DB_USER] = \$DB_USER\n\
    env[DB_PASSWORD] = \$DB_PASSWORD" >> /etc/php7/php-fpm.d/www.conf && \
    # SSL configuration
    echo -e '\
    LoadModule ssl_module /usr/lib/apache2/mod_ssl.so\n\
    Listen 443\n\
    SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH\n\
    SSLProtocol All -SSLv2 -SSLv3\n\
    SSLHonorCipherOrder On\n\
    #Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains"\n\
    #Header always set X-Frame-Options DENY\n\
    #Header always set X-Content-Type-Options nosniff\n\
    #SSLCompression off\n\
    #SSLSessionTickets off\n\
    #SSLUseStapling on\n\
    #SSLStaplingCache "shmcb:logs/stapling-cache(150000)"\n\
    #SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"\n\
    <Virtualhost *:80>\n\
        Redirect / https://%{HTTP_HOST}%{REQUEST_URI}\n\   
    </Virtualhost>\n\
    <Virtualhost _default_:443>\n\
        SSLEngine on\n\
        SSLCertificateFile /etc/ssl/zeit.crt\n\
        SSLCertificateKeyFile /etc/ssl/zeit.key\n\
        #<FilesMatch "\.(cgi|shtml|phtml|php)$">\n\
        #    SSLOptions +StdEnvVars\n\
        #</FilesMatch>\n\
    </Virtualhost> \
    ' > /etc/apache2/conf.d/ssl.conf

RUN echo -e "#!/bin/sh\n\
    openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout /etc/ssl/zeit.key -out /etc/ssl/zeit.crt -subj \"/C=US/ST=Denial/L=Springfield/O=Dis/CN=*\" &> /dev/null \n\
    sed -i \"s/^user = .*/user = www-data/g\" /etc/php7/php-fpm.d/www.conf\n\
    sed -i \"s/^group = .*/group = www-data/g\" /etc/php7/php-fpm.d/www.conf\n\
    sed -i \"s/^memory_limit = .*/memory_limit = \${MEMORY_LIMIT:-128M}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^max_execution_time = .*/max_execution_time = \${MAX_EXECUTION_TIME:-30}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^upload_max_filesize = .*/upload_max_filesize = \${UPLOAD_MAX_FILESIZE:-16M}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^post_max_size = .*/post_max_size = \${UPLOAD_MAX_FILESIZE:-16M}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^display_errors = .*/display_errors = \${DISPLAY_ERRORS:-Off}/g\" /etc/php7/php.ini\n\
    sed -i \"s/^display_startup_errors = .*/display_startup_errors = \${DISPLAY_ERRORS:-Off}/g\" /etc/php7/php.ini\n\
    /usr/bin/memcached -u memcached -d\n\
    /usr/sbin/php-fpm7\n\
    /usr/sbin/httpd\n\
    tail -f /var/log/apache2/access.log\
    " > /run.sh

EXPOSE 443

CMD ["/run.sh"]