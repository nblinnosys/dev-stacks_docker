<?php
/* MGA — includes/rollbar.php (DEV). Chemins ABSOLUS dans le conteneur : la source
 * est bind-montée sur /var/www/html/current. */
require_once('/var/www/html/current/vendor/autoload.php');
require_once('/var/www/html/current/secure/php/constants.php');

use \Rollbar\Rollbar;
use \Rollbar\Payload\Level;

Rollbar::init(
    array(
        'access_token' => ACCESS_TOKEN,
        'environment'  => ENVIRONNEMENT_ROLLBAR
    )
);
?>
