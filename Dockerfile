FROM php:8.1-cli AS base

# Install dependencies
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    apt-utils curl git zip unzip libbz2-dev openssl gcc make autoconf \
    libc6-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev \
    zlib1g-dev libzip-dev pkg-config && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install PHP extensions via PECL
RUN pecl install igbinary-3.2.15 && \
    pecl install --configureoptions='enable-redis-igbinary="yes"' redis-6.2.0 && \
    pecl install protobuf-4.27.2 grpc-1.64.1  && \
    rm -rf /tmp/pear

# Install PHP extensions via source (php-ext-lz4)
RUN git clone --recursive --depth=1 https://github.com/kjdev/php-ext-lz4.git /tmp/php-ext-lz4 && \
    cd /tmp/php-ext-lz4 && \
    phpize && ./configure && make && make install && \
    rm -rf /tmp/php-ext-lz4

# Install PHP extensions via docker-php-ext-install
RUN docker-php-ext-install bcmath bz2 mysqli pdo_mysql pcntl zip && \
    docker-php-ext-configure gd && docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-configure intl && docker-php-ext-install intl

# Install PHP-SPX
RUN git clone --recursive --depth=1 https://github.com/NoiseByNorthwest/php-spx.git /tmp/php-spx && \
    cd /tmp/php-spx && \
    phpize && ./configure && make && make install && \
    rm -rf /tmp/php-spx

# Install and configure Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug && \
    echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_host=172.20.0.1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.idekey=dicoding-debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    rm -rf /tmp/pear