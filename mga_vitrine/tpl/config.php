<?php
/* mga-vitrine — include/config.php (DEV, généré via envsubst).
 * DB : schéma mga_vitrine sur le conteneur mga_db (rôle dev/mga), réseau `mga`. */

// Global
$serveur = '${MGAV_ENV}';
define('ENVIRONNEMENT', $serveur); // developpement / production / pp
define('BASE_URL', '');
define('ROOT', __DIR__ . '/../'); // Ne pas changer
define("REAL_PATH", '/var/www/html/current');
define("PATH_TO_THEME", '${MGAV_THEME_PATH}');
define("REAL_PATH_TO_THEME", '/var/www/html/current/porto');
define("SESSION_NAME", 'mga');
define("SITE_NAME", 'MaGarantieAuto');
define("SITE_URL", '${MGAV_SITE_URL}');
define("SITE_URL_IMAGE", '${MGAV_SITE_URL_IMAGE}');
define("DEVIS_URL", '${MGAV_DEVIS_URL}');

define('ROLLBAR_SERVEUR_TOKEN', '${MGAV_ROLLBAR_TOKEN}');
define('GITHUB_WEBHOOKS_TOKEN', '');
define('GITHUB_API_TOKEN', '${MGAV_GITHUB_API_TOKEN}');

// Connection DB (schéma vitrine hébergé par le conteneur mga_db du rôle mga)
define('DB_HOST', "${MGAV_DB_HOST}");
define('DB_USER', "${MGAV_DB_USER}");
define('DB_PASSWD', "${MGAV_DB_PASS}");
define('DB_DBASE', "${MGAV_DB_NAME}");
// 2e connexion : base MGA PRINCIPALE (mga_mb) pour le blog/actualités.
define('DB_DBASE_MGA', "${MGAV_DB_NAME_MGA}");

// Mail (PHPMailer en SMTP direct vers office365)
define('MAIL_USER', '${MGAV_MAIL_USER}');
define('MAIL_PASSWD', '${MGAV_MAIL_PASS}');
define('MAIL_FROM', '${MGAV_MAIL_USER}');
define('MAIL_FROM_NAME', 'Noreply InnoSys');
define('MAIL_TO_CRON', 'mbragance@innosys.fr,fsalinier@innosys.fr');
define('MAIL_REPLY', '');
define('MAIL_TO', '${MGAV_MAIL_TO}');

define("MAIL_HOST", '${MGAV_MAIL_HOST}');
define("MAIL_PORT", ${MGAV_MAIL_PORT});

//ShortPixel
define('SHORTPIXEL_API', '${MGAV_SHORTPIXEL}');
define('SHORTPIXEL_QUOTA', 60);

define('RECAPTCHA_KEY','${MGAV_RECAPTCHA_KEY}');
define('RECAPTCHA_SECRET','${MGAV_RECAPTCHA_SECRET}');

if (isset($_GET['source_formulaire']) && $_GET['source_formulaire'] != "") {
        setcookie('source_formulaire', $_GET['source_formulaire'], time() + 31536000);  // 1 an
}

if(isset($_COOKIE['source_formulaire']) && $_COOKIE['source_formulaire']!=''){
        define('SOURCE_FORMULAIRE','?source_formulaire='.$_COOKIE['source_formulaire']);
}else{
        define('SOURCE_FORMULAIRE','');
}
