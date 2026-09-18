# =============================================================================
# dev/assurmix/Dockerfile — Assurmix en DEV : PHP 5.6 + Apache (Ubuntu 22.04).
#   Back-office « pro » (code legacy) bind-monté. Pas de base ici : se connecte à
#   portomix_data (dev/shared-db) via le réseau assurenv. DocumentRoot = pro/.
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
    php5.6 libapache2-mod-php5.6 \
    php5.6-cli php5.6-common php5.6-curl php5.6-gd php5.6-intl \
    php5.6-mbstring php5.6-mysql php5.6-mysqlnd php5.6-soap php5.6-xml php5.6-zip \
  && rm -rf /var/lib/apt/lists/*

# Composer LTS 2.2 (compatible PHP 5.6 ; les 2.3+ exigent PHP >= 7.2)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --2.2

RUN a2enmod rewrite headers \
  && a2dissite 000-default \
  && mkdir -p /var/log/apache2

EXPOSE 80
WORKDIR /var/www/html/assurmix
