<?php
// Portomix DEV -> include/config.php (généré via envsubst). DB partagée portomix_data.

// Pathing
define('BASE_URL', '');
define('SITE_URL',    '${PORTO_SITE_URL}');
define('SITE_URL_FR', '${PORTO_SITE_URL}');
define('SITE_URL_EN', '${PORTO_SITE_URL}');
define('CURL_URL',    '${PORTO_SITE_URL}');
define('REAL_PATH',   '/var/www/html/portomix');
define('PUSH_URL',    '${PORTO_SITE_URL}');
define('TEMP_URL',    '${PORTO_SITE_URL}/documents/tmp');

// Environnement (dev : on affiche les erreurs)
define('ENVIRONNEMENT',     'developpement');
define("LAST_LEVEL_DOMAIN", "rec");

// Rollbar
define('ROLLBAR_SERVEUR_TOKEN', 'afc22f6a16e342eaa4cded0f0841ceb9');
define('ROLLBAR_ENVIRONMENT',   'DEV - PORTOMIX');

// Payline (TEST)
define('PAYLINE_WSDL_PATH',           '/var/www/html/portomix/lib/Payline/wsdl/');
define('PAYLINE_MERCHANT_ID',         '48924118022129');
define('PAYLINE_ACCESS_KEY',          'w1ZECAXZnRkqCjYIVmPd');
define('PAYLINE_PRODUCTION',          false);
define('PAYLINE_ASKI_CONTRACT_NUMBER',   '1234567');
define('PAYLINE_AVETO_CONTRACT_NUMBER',  '1234567_1');
define('PAYLINE_AKIDS_CONTRACT_NUMBER',  '1234567_3');
define('PAYLINE_ASPORT_CONTRACT_NUMBER', '1234567_2');

// Signassur (TEST)
define("SIGNASSUR_MERCHANT_ID",     "4E7hXmjUqsJq6L");
define("SIGNASSUR_APPLICATION_KEY", "91ef05985ac3e75536f75757db1e11f4");

// Session
define("SESSION_NAME", 'assurmix');

// Database (partagée Portomix + Assurmix -> conteneur portomix_data)
define('DB_SERVER', "portomix_data");
define('DB_USER',   "${PORTO_DB_USER}");
define('DB_PASS',   "${PORTO_DB_PASS}");
define('DB_NAME',   "assurmix");

// CoreFramework
define("GUEST_NAME", "Visiteur");
define("COOKIE_EXPIRE", 60*60*24*100);
define("COOKIE_PATH", "/");
define("supersecret_hash_padding",   'String used to pad out small strings for a sha1 encryption');
define("supersecret_hash_padding_2", 'Other String used to pad out small strings for a sha1 encryption');

// Mail (dev : identifiants de test)
define('MAIL_USER_DEV', 'noreply@innosys.fr');
define('MAIL_USER_PROD', 'sendmailo365@assurmix.fr');
define('MAIL_PASSWD_DEV', 'L?lTJ.Y3RUGaRh%}tG?F');
define('MAIL_PASSWD_PROD', 'nwa4arw9BWA-vqz8xkw');
define('MAIL_DEV', 'test@assurmix.fr');
define('MAIL_DEV_CC', '');
define('MAIL_DEV_BCC', '');

// Captcha
define('CAPTCHA_PUBLIC_KEY',  '6LdmFnAUAAAAAB49Ug4_ngaK4fFb_04ujH3cBh2n');
define('CAPTCHA_PRIVATE_KEY', '6LdmFnAUAAAAALLlLIe0m-n-E34Lbdf3muZQQMg8');

// Shortpixel
define('SHORTPIXEL_API', 'UoPymKSQ1FlhtqhVEzQi');

// Facebook Pixel
define('PIXELFACEBOOK_API', '441226106733491');
