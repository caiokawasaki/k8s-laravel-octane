ARG PHP_EXTS="bcmath ctype fileinfo mbstring pdo pdo_mysql dom pcntl"
ARG PHP_PECL_EXTS="redis"

FROM composer:2.5 as composer_base

ARG PHP_EXTS
ARG PHP_PECL_EXTS

RUN mkdir -p /opt/apps/k8s-application /opt/apps/k8s-application/bin

WORKDIR /opt/apps/k8s-application

RUN addgroup -S composer && \
    adduser -S composer -G composer && \
    chown -R composer /opt/apps/k8s-application && \
    apk add --virtual build-dependencies --no-cache pcre-dev ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) ${PHP_EXTS} && \
    pecl update-channels && \
    pecl install ${PHP_PECL_EXTS} && \
    docker-php-ext-enable redis.so && \
    apk del build-dependencies

USER composer

COPY --chown=composer composer.json composer.lock ./

RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=composer . .

RUN composer install --no-dev --prefer-dist

FROM node:16 as frontend

COPY --from=composer_base /opt/apps/k8s-application /opt/apps/k8s-application

WORKDIR /opt/apps/k8s-application

RUN npm install

FROM php:8.2-alpine as cli

ARG PHP_EXTS
ARG PHP_PECL_EXTS

WORKDIR /opt/apps/k8s-application

RUN apk add --virtual build-dependencies --no-cache pcre-dev ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) ${PHP_EXTS} && \
    pecl update-channels && \
    pecl install ${PHP_PECL_EXTS} && \
    docker-php-ext-enable redis.so && \
    apk del build-dependencies

COPY --from=composer_base /opt/apps/k8s-application /opt/apps/k8s-application
COPY --from=frontend /opt/apps/k8s-application/public /opt/apps/k8s-application/public

FROM php:8.2-fpm-alpine as fpm_server

ARG PHP_EXTS
ARG PHP_PECL_EXTS

WORKDIR /opt/apps/k8s-application

RUN apk add --virtual build-dependencies --no-cache pcre-dev ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) ${PHP_EXTS} && \
    pecl update-channels && \
    pecl install ${PHP_PECL_EXTS} && \
    docker-php-ext-enable redis.so && \
    apk del build-dependencies

USER www-data

COPY --from=composer_base --chown=www-data /opt/apps/k8s-application /opt/apps/k8s-application
COPY --from=frontend --chown=www-data /opt/apps/k8s-application/public /opt/apps/k8s-application/public

RUN php artisan event:cache && \
    php artisan route:cache

FROM nginx:1.25-alpine as web_server

WORKDIR /opt/apps/k8s-application

COPY docker/production/nginx.conf.template /etc/nginx/templates/default.conf.template

COPY --from=frontend /opt/apps/k8s-application/public /opt/apps/k8s-application/public

FROM cli as cron

WORKDIR /opt/apps/k8s-application

RUN touch laravel.cron && \
    echo "* * * * * cd /opt/apps/k8s-application && php artisan schedule:run" >> laravel.cron && \
    crontab laravel.cron

CMD ["crond", "-l", "2", "-f"]

FROM cli
