# =============================================================================
# dev/odc/Dockerfile — ODC (Laravel + Backpack) en DEV : Apache + PHP 8.1.
#   Identique à l'image recette (Ubuntu 22.04) : le code est bind-monté (clone
#   app/), aucun COPY. Pas de releases : le conteneur sert directement app/.
# =============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

RUN apt-get update && apt-get install -y \
    software-properties-common \
    ca-certificates \
    ssl-cert \
    curl wget \
    zip unzip \
    git \
    vim nano \
    default-mysql-client \
  && rm -rf /var/lib/apt/lists/*

# Apache + PHP 8.1 (dépôt ondrej/php pour PHP 8.1 sur Ubuntu 22.04)
RUN add-apt-repository ppa:ondrej/php -y \
  && apt-get update \
  && apt-get install -y \
    apache2 \
    php8.1 libapache2-mod-php8.1 \
    php8.1-cli \
    php8.1-common \
    php8.1-curl \
    php8.1-gd \
    php8.1-igbinary \
    php8.1-imagick \
    php8.1-intl \
    php8.1-mbstring \
    php8.1-mysql \
    php8.1-redis \
    php8.1-soap \
    php8.1-xml \
    php8.1-xmlrpc \
    php8.1-zip \
    php8.1-bcmath \
  && rm -rf /var/lib/apt/lists/*

# Composer 2
RUN curl -sS https://getcomposer.org/installer \
    | php -- --install-dir=/usr/local/bin --filename=composer

# Modules Apache (rewrite = routing Laravel ; headers ; setenvif ; ssl = TLS dev)
RUN a2enmod rewrite headers setenvif ssl \
  && a2dissite 000-default \
  && mkdir -p /var/log/apache2

# Réglages PHP dev : uploads + mémoire + affichage des erreurs.
RUN printf 'memory_limit = 512M\nupload_max_filesize = 300M\npost_max_size = 320M\nmax_execution_time = 120\ndisplay_errors = On\n' \
    > "/etc/php/8.1/apache2/conf.d/zz-odc.ini" \
  && cp "/etc/php/8.1/apache2/conf.d/zz-odc.ini" "/etc/php/8.1/cli/conf.d/zz-odc.ini"

EXPOSE 80
WORKDIR /var/www/html/odc
