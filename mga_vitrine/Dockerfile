# =============================================================================
# dev/mga_vitrine/Dockerfile — mga-vitrine en DEV : PHP 7.4 + Apache.
#   Code « raw » (routeur bramus) bind-monté (clone app/). InnoCore (dépendance
#   privée) installé par dev.sh via HTTPS+token (PAS de clé SSH nécessaire).
#
#   ⚠ php:7.4-apache = Debian bullseye (EOL) : les miroirs deb.debian.org purgent
#   les paquets -> apt 404. On bascule sur snapshot.debian.org (figé) + on désactive
#   le pipelining HTTP (snapshot le gère mal).
# =============================================================================
FROM php:7.4-apache

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

# --- Dépôts snapshot (bullseye EOL) ------------------------------------------
RUN set -eux; \
  printf '%s\n' \
    'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20260701T000000Z bullseye main' \
    'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20260701T000000Z bullseye-updates main' \
    'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/20260701T000000Z bullseye-security main' \
    > /etc/apt/sources.list; \
  printf '%s\n' \
    'Acquire::Check-Valid-Until "false";' \
    'Acquire::http::Pipeline-Depth "0";' \
    'Acquire::Retries "5";' \
    > /etc/apt/apt.conf.d/99snapshot

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git unzip zip \
      libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
  && rm -rf /var/lib/apt/lists/*

# Extensions PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" \
       mysqli pdo_mysql intl gd zip bcmath \
  && rm -rf /var/lib/apt/lists/*

# mbstring (requis par phpspreadsheet) : installé seulement s'il n'est pas déjà
# compilé dans l'image de base (robuste quelle que soit la variante php:7.4).
RUN if ! php -m | grep -qiw mbstring; then docker-php-ext-install mbstring; fi

# Composer 2.7 (comme recette)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN a2enmod rewrite headers \
  && a2dissite 000-default

RUN printf 'display_errors = Off\nlog_errors = On\nerror_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT\n' \
      > "$PHP_INI_DIR/conf.d/zz-mga-vitrine.ini"

EXPOSE 80
WORKDIR /var/www/html/current
