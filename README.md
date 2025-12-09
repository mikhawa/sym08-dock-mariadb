# Symfony 8 Dockérisation

## Sous Windows dans WSL2


#### Ouvrir une fenêtre sur Ubuntu dans WSL

Installer Docker, composer, symfony-cli, nvim et configurer git


Atteindre le dossier voulu : 

    cd /home/mikhawa/

puis 
    
    mkdir sym08-dock-mariadb

puis

    cd sym08-dock-mariadb

Créer avec nvim : 

```bash
Dockerfile

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
```

Effacer `composer.override.yaml` ou renommer en `\\wsl.localhost\Ubuntu\home\mikhawa\sym08-dock-mariadb\compose.override.yaml.back`


Puis compose.yaml

```bash
services:
  php:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USER_ID: ${USER_ID:-1000}
        GROUP_ID: ${GROUP_ID:-1000}
    container_name: symfony_php
    volumes:
      - .:/var/www/symfony
    networks:
      - symfony_network
    depends_on:
      - mariadb


  nginx:
    image: nginx:alpine
    container_name: symfony_nginx
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/symfony
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - symfony_network
    depends_on:
      - php


  mariadb:
    image: mariadb:11.2
    container_name: symfony_mariadb
    environment:
      MYSQL_ROOT_PASSWORD: vdb123
      MYSQL_DATABASE: symfony_db
      MYSQL_USER: symfony_user
      MYSQL_PASSWORD: vdb123
    ports:
      - "3308:3306"
    healthcheck:
      test: [ "CMD", "healthcheck.sh", "--connect", "--innodb_initialized" ]
      start_period: 60s
      interval: 10s
      timeout: 5s
      retries: 3
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - symfony_network


  phpmyadmin:
    image: phpmyadmin:latest
    container_name: symfony_phpmyadmin
    environment:
      PMA_HOST: symfony_mariadb
      PMA_USER: symfony_user
      PMA_PASSWORD: vdb123
    ports:
      - "8081:80"
    networks:
      - symfony_network
    depends_on:
      - mariadb


networks:
  symfony_network:
    driver: bridge


volumes:
  mariadb_data:

```



Puis \\wsl.localhost\Ubuntu\home\mikhawa\sym74-dock-1\docker\nginx\default.conf

```bash
server {
    listen 80;
    server_name localhost;
    root /var/www/symfony/public;


    location / {
        try_files $uri /index.php$is_args$args;
    }


    location ~ ^/index\.php(/|$) {
        fastcgi_pass php:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        internal;
    }


    location ~ \.php$ {
        return 404;
    }


    error_log /var/log/nginx/symfony_error.log;
    access_log /var/log/nginx/symfony_access.log;
}

```


Puis 

    docker-compose build

Puis 

    docker-compose up -d

Pour fermer

    docker-compose down -v

Accéder à WSL : 

    \\wsl$\

#### Chemins : 

Symfony : 

http://localhost:8080/

PHPMyAdmin : 

http://localhost:8081

