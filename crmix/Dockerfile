# =============================================================================
# dev/crmix/Dockerfile — CRMIX en DEV : PHP 7.3 / Apache (Symfony/InnoCore).
#   Code bind-monté (clone app/ -> /var/www/html/current). Thème Metronic monté.
#   InnoCore installé par dev.sh via HTTPS+token (PAS de clé SSH ici).
#   ⚠ php:7.3.x-apache-buster = Debian Buster EOL -> dépôts archive.debian.org.
# =============================================================================
FROM php:7.3.13-apache-buster

RUN sed -i -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' \
           -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
           -e '/buster-updates/d' /etc/apt/sources.list

RUN apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
      unzip git default-mysql-client zip libzip-dev libpng-dev \
    && docker-php-ext-install pdo_mysql zip gd \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && rm -rf /var/lib/apt/lists/*

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

RUN a2enmod rewrite headers

RUN printf 'memory_limit = 1024M\nmax_execution_time = 300\nmax_input_time = 300\n' > "$PHP_INI_DIR/conf.d/zz-crmix.ini"

WORKDIR /var/www/html/current
