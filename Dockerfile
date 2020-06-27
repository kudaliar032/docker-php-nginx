FROM php:7.2-fpm-alpine

# install system dependencies
RUN apk add --no-cache git \
  icu-dev \
  libpng-dev \
  libzip-dev \
  libjpeg-turbo-dev \
  supervisor \
  nginx

# install PHP extensions and composer
RUN apk add --no-cache --virtual .build-deps autoconf gcc g++ make linux-headers && \
  docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ && \
  docker-php-ext-install intl pdo_mysql mysqli exif bcmath gd zip sockets && \
  pecl install redis grpc && docker-php-ext-enable redis grpc && \
  docker-php-source delete && \
  apk del .build-deps && \
  curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/bin/composer && \
  chmod +x /usr/bin/composer

# setup nginx
RUN mkdir -p /run/nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf

# setup supervisor
COPY config/supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

# set working directory
WORKDIR /app/www
