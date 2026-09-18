<?php
// Assurmix DEV -> pro/secure/php/config.php.
define('REAL_PATH', '/var/www/html/assurmix/');

define("DB_SERVER", "portomix_data");
define("DB_USER",   "${ASSUR_DB_USER}");
define("DB_PASS",   "${ASSUR_DB_PASS}");
define("DB_NAME",   "assurmix");

define("GUEST_NAME", "Guest");
define("COOKIE_EXPIRE", 60*60*24*100);
define("COOKIE_PATH", "/");

define("LAST_LEVEL_DOMAIN", "rec");

define("EMAIL_FROM_NAME", "Assur Mix");
define("EMAIL_FROM_ADDR", "www.assurmix.fr");

define("ALL_LOWERCASE", false);

define("supersecret_hash_padding",   'String used to pad out small strings for a sha1 encryption');
define("supersecret_hash_padding_2", 'Other String used to pad out small strings for a sha1 encryption');

define("REPEAT_EMAIL", true);
define("REPEAT_PASSWORD", true);

define("RESETPASSWORDLINK",  "https://" . LAST_LEVEL_DOMAIN . ".assurmix.fr/pro/secure/resetpassword.php");
define("CONFIRMACCOUNTLINK", "https://" . LAST_LEVEL_DOMAIN . ".assurmix.fr/pro/secure/php/confirm.php");

define("PUBLICKEY",  "6LciQ7oSAAAAAGhNYIHEqmkcMX97NvFQqLnV8lNb");
define("PRIVATEKEY", "6LciQ7oSAAAAAFIEupLjV7pCXzGAgcpOE4Igdj3Y");
?>
