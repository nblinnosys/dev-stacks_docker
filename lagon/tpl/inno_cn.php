<?php
// Lagon7 DEV -> extranet/include/inno_cn.php (généré via envsubst). Connexion mysqli.
define('DB_HOST',     "${LAGON_DB_HOST}");
define('DB_USER',     "${LAGON_DB_USER}");
define('DB_PASSWD',   "${LAGON_DB_PASS}");
define('DB_DBASE',    "${LAGON_DB_NAME}");
define('ADMIN_EMAIL', "info@innosys.fr");
define('ADRES_FROM',  "info@innosys.fr");
define('EMAIL_FROM',  "info@innosys.fr");

define('URL_HOST', $_SERVER['HTTP_HOST']);

//CONSTANTES FICHIERS
define("MAIL_SPOOL", "/home/user/Maildir/");
define("BASE_URL",   "${LAGON_EXTRANET_URL}");

define("LOGO_CLIENT",       "graphics/logo.gif");
define("LOGO_CLIENT_ALT",   "Lagon Courtage");
define("LOGO_CLIENT_WIDTH", "100");
define("APROFI", "0");

$cn = null;
$cn = db_connect() or connect_error();

function db_connect()
    {
    $link = new mysqli(DB_HOST, DB_USER, DB_PASSWD, DB_DBASE);
    if ($link)
        {
        $link->set_charset("utf8");
        return($link);
        }
    else
        return (FALSE);
    }

function connect_error()
    {
    echo '<h1>'.mysqli_error().'</h1>';
    exit();
    }
?>
