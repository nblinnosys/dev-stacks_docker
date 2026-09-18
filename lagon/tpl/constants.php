<?php
// Lagon7 DEV -> extranet/secure/php/constants.php (généré via envsubst).
define("DB_SERVER", "${LAGON_DB_HOST}");
define("DB_USER",   "${LAGON_DB_USER}");
define("DB_PASS",   "${LAGON_DB_PASS}");
define("DB_NAME",   "${LAGON_DB_NAME}");

define("GUEST_NAME", "Guest");
define("COOKIE_EXPIRE", 60*60*24*100);
define("COOKIE_PATH", "/");

define("EMAIL_FROM_NAME", "Lagon Courtage");
define("EMAIL_FROM_ADDR", "contact@lagon-courtage.fr");

define("ALL_LOWERCASE", false);

define("supersecret_hash_padding",'String used to pad out small strings for a sha1 encryption');
define("supersecret_hash_padding_2",'Other String used to pad out small strings for a sha1 encryption');

define("REPEAT_EMAIL", false);
define("REPEAT_PASSWORD", false);

$url = sprintf(
    "%s://%s",
    isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] != 'off' ? 'https' : 'http',
    $_SERVER['SERVER_NAME']
);
define("RESETPASSWORDLINK", $url."/extranet/reset_pass.php");
define("CONFIRMACCOUNTLINK", $url."/extranet/acc_confirm.php");

define("PUBLICKEY",  "${LAGON_RECAPTCHA_PUB}");
define("PRIVATEKEY", "${LAGON_RECAPTCHA_PRIV}");
?>
