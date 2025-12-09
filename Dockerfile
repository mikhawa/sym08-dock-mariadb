FROM php:8.4-fpm


# Arguments
ARG USER_ID=1000
ARG GROUP_ID=1000


# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    mariadb-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    intl \
    mysqli \
    opcache \
    zip \
    gd


# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer


# Configuration opcache pour le dev
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/opcache.ini


# Création d'un utilisateur non-root
RUN groupadd -g ${GROUP_ID} appuser && \
    useradd -u ${USER_ID} -g appuser -m appuser


WORKDIR /var/www/symfony


# Permissions
RUN chown -R appuser:appuser /var/www


USER appuser


EXPOSE 9000
