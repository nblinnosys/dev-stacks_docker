<?php
// Assurmix DEV -> pro/secure/php/constants.php. DB PARTAGÉE = portomix_data.
define("DB_SERVER", "portomix_data");
define("DB_USER",   "${ASSUR_DB_USER}");
define("DB_PASS",   "${ASSUR_DB_PASS}");
define("DB_NAME",   "assurmix");

define("GUEST_NAME", "Guest");
define("COOKIE_EXPIRE", 60*60*24*100);
define("COOKIE_PATH", "/");

define("SIGNASSUR_MERCHANT_ID",     "11062302000000");
define("SIGNASSUR_APPLICATION_KEY", "6ad64ae70b039a59d6bfcf805371f559");

define("ALL_LOWERCASE", false);

define("supersecret_hash_padding",   'String used to pad out small strings for a sha1 encryption');
define("supersecret_hash_padding_2", 'Other String used to pad out small strings for a sha1 encryption');
