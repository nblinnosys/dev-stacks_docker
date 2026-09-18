# =============================================================================
# dev/mga/Dockerfile — MGA en DEV : PHP 8.2 + Apache (repris du rôle recette).
#   Code « raw » bind-monté (clone app/). Patches PHP 8 appliqués par dev.sh.
# =============================================================================
FROM php:8.2-apache

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

RUN apt-get -o Acquire::Check-Valid-Until=false update \
  && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git unzip zip \
      libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
      postfix \
  && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" \
       mysqli pdo_mysql intl gd zip \
  && rm -rf /var/lib/apt/lists/*

# Composer 2.7 (comme recette : < 2.8 pour install déterministe)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN a2enmod rewrite headers \
  && a2dissite 000-default

RUN printf 'display_errors = Off\nlog_errors = On\nerror_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT\n' \
      > "$PHP_INI_DIR/conf.d/zz-mga.ini"

EXPOSE 80
WORKDIR /var/www/html/current
