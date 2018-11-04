FROM jexperton/php:7.2-apache

ARG MEMORY_LIMIT

RUN apk add --update --no-cache apache2-ssl memcached

RUN echo -e "\
    env[DB_HOST] = \$DB_HOST\n\
    env[DB_NAME] = \$DB_NAME\n\
    env[DB_USER] = \$DB_USER\n\
    env[DB_PASSWORD] = \$DB_PASSWORD\
    " >> /etc/php7/php-fpm.d/www.conf && \
    # PHP Memory limit
    sed -i "s/^memory_limit = .*/memory_limit = ${MEMORY_LIMIT:-128M}/g" /etc/php7/php.ini && \
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

RUN echo -e "$(head -1 /run.sh)\n\
    openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout /etc/ssl/zeit.key -out /etc/ssl/zeit.crt -subj \"/C=US/ST=Denial/L=Springfield/O=Dis/CN=*\" &> /dev/null \n\
    #/usr/bin/memcached -u memcached -d\n\
    $(head -4 /run.sh | tail -3)" > /run.sh

EXPOSE 443

CMD ["/run.sh"]