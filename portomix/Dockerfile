# =============================================================================
# dev/portomix/Dockerfile — Portomix en DEV : PHP 7.4 + Apache (Ubuntu 22.04).
#   Code moderne (Portomix2025) bind-monté (clone app/). Pas de base ici : se
#   connecte au conteneur portomix_data (dev/shared-db) via le réseau assurenv.
# =============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

RUN apt-get update && apt-get install -y \
    apt-utils dialog software-properties-common ca-certificates \
    curl wget zip unzip git vim nano postfix tzdata \
  && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:ondrej/php -y \
  && add-apt-repository ppa:ondrej/apache2 -y \
  && apt-get update \
  && apt-get install -y \
    apache2 \
    php7.4 libapache2-mod-php7.4 \
    php7.4-cli php7.4-common php7.4-curl php7.4-gd php7.4-intl \
    php7.4-mbstring php7.4-mysql php7.4-soap php7.4-xml php7.4-zip php7.4-bcmath \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN a2enmod rewrite headers \
  && a2dissite 000-default \
  && mkdir -p /var/log/apache2

EXPOSE 80
WORKDIR /var/www/html/portomix
