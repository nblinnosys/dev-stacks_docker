<?php
// Lagon7 DEV -> extranet/include/rollbar.php (généré via envsubst).
require '/var/www/html/current/extranet/vendor/autoload.php';

use \Rollbar\Rollbar;
use \Rollbar\Payload\Level;

Rollbar::init(array(
    'access_token' => '${LAGON_ROLLBAR_TOKEN}',
    'environment'  => '${LAGON_ENV}',
    'root'         => '/var/www/html/current'
));
?>
