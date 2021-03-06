FROM php:7.4-fpm-alpine

LABEL maintainer="adityarahman032@gmail.com"

ENV PHP_NGINX_USER web-app
ENV PHP_NGINX_GROUP web-app
ENV PHP_NGINX_UID 1001
ENV PHP_NGINX_GID 1002

RUN set -xe \
  && curl https://getcomposer.org/installer -o /tmp/composer-setup.php \
  && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && apk add --no-cache \
      git \
      supervisor \
      nginx \
      openldap \
      libpng \
      libjpeg-turbo \
      libstdc++ \
      freetds \
      unixodbc \
      gnupg \
      libzip \
      imap-dev \
      imagemagick \
      krb5 \
  && curl -o /tmp/msodbcsql17_17.5.2.2-1_amd64.apk https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.2.2-1_amd64.apk \
  && curl -o /tmp/mssql-tools_17.5.2.1-1_amd64.apk https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.2.1-1_amd64.apk \
  && curl -o /tmp/msodbcsql17_17.5.2.2-1_amd64.sig https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.2.2-1_amd64.sig \
  && curl -o /tmp/mssql-tools_17.5.2.1-1_amd64.sig https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.2.1-1_amd64.sig \
  && curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import - \
  && gpg --verify /tmp/msodbcsql17_17.5.2.2-1_amd64.sig /tmp/msodbcsql17_17.5.2.2-1_amd64.apk \
  && gpg --verify /tmp/mssql-tools_17.5.2.1-1_amd64.sig /tmp/mssql-tools_17.5.2.1-1_amd64.apk \
  && apk add --allow-untrusted /tmp/msodbcsql17_17.5.2.2-1_amd64.apk \
  && apk add --allow-untrusted /tmp/mssql-tools_17.5.2.1-1_amd64.apk \
  && apk add --no-cache --virtual .build-deps \
      $PHPIZE_DEPS \
      openldap-dev \
      libpng-dev \
      libjpeg-turbo-dev \
      freetds-dev \
      unixodbc-dev \
      libzip-dev \
      imagemagick-dev \ 
      krb5-dev \
      openssl-dev \
  && docker-php-source extract \
  && pecl install \
      sqlsrv \
      pdo_sqlsrv \
      redis \
      imagick \
  && docker-php-ext-configure gd --with-jpeg=/usr/include \
  && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
  && docker-php-ext-install \
      ldap \
      gd \
      pdo_mysql \
      mysqli \
      zip \
      pdo_dblib \
      imap \
      bcmath \
  && docker-php-ext-enable \
      sqlsrv \
      pdo_sqlsrv \
      redis \
      imagick \
  && mkdir -p /run/nginx \
  && addgroup -g $PHP_NGINX_GID $PHP_NGINX_GROUP \
  && adduser -D -u $PHP_NGINX_UID -G $PHP_NGINX_GROUP $PHP_NGINX_USER \
  && adduser $PHP_NGINX_USER nginx \
  && adduser $PHP_NGINX_USER www-data \
  && docker-php-source delete \
  && apk del .build-deps && rm -rf /tmp/*

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf
COPY config/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/info.php /var/www/html/public/index.php
COPY config/supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

WORKDIR /var/www/html

EXPOSE 80
