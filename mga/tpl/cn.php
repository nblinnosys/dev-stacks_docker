<?php
/* MGA — includes/cn.php (DEV, généré via envsubst). Connexion mysqli mga_mb. */
define('DB_HOST',   '${MGA_DB_HOST}');
define('DB_USER',   '${MGA_DB_USER}');
define('DB_PASSWD', '${MGA_DB_PASS}');
define('DB_DBASE',  '${MGA_DB_NAME}');

define('ADMIN_EMAIL', 'fsalinier@inassur.fr');
define('EMAIL_FROM',  'fsalinier@inassur.fr');
define('ADRES_FROM',  'fsalinier@inassur.fr');

$mysqli = null;
$mysqli = db_connect() or connect_error();

function db_connect()
{
    $link = mysqli_connect(DB_HOST, DB_USER, DB_PASSWD, DB_DBASE);
    if ($link) {
        mysqli_query($link, "SET NAMES UTF8");
        mysqli_query($link, "SET CHARACTER SET utf8");
        return $link;
    }
    return false;
}

function connect_error()
{
    if (mysqli_connect_errno()) {
        echo "Failed to connect to MySQL: " . mysqli_connect_error();
    }
    exit();
}
?>
