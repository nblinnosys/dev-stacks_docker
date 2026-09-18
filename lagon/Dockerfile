# =============================================================================
# dev/lagon/Dockerfile — Lagon7 en DEV : PHP 7.4 + Apache (legacy PHPExcel/Editor).
#   Code bind-monté (clone app/). 2 sites (public + extranet) via vhost monté.
#   ⚠ php:7.4-apache = Debian bullseye (EOL) -> dépôts snapshot.debian.org figés.
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
      postfix \
  && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" mysqli pdo_mysql intl gd zip \
  && rm -rf /var/lib/apt/lists/*

# mbstring : requis (mb_internal_encoding). Installé seulement s'il n'est pas déjà
# compilé dans l'image de base (robuste quelle que soit la variante php:7.4).
RUN if ! php -m | grep -qiw mbstring; then docker-php-ext-install mbstring; fi

# Composer 2.7 (compatible PHP 7.4 ; < 2.8 pour twig 3.2->3.4 sans blocage advisory)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN postconf -e "inet_protocols=ipv4" || true

RUN a2enmod rewrite headers \
  && a2dissite 000-default

EXPOSE 80
WORKDIR /var/www/html/current
