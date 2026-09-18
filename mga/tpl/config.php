<?php if (!defined('DATATABLES')) exit(); // Ensure being used in DataTables env.
/* MGA — Editor-PHP config (DEV, généré via envsubst). Connexion Editor -> mga_mb. */

error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT);
ini_set('display_errors', '0');

$sql_details = array(
    "type" => "Mysql",
    "user" => "${MGA_DB_USER}",
    "pass" => "${MGA_DB_PASS}",
    "host" => "${MGA_DB_HOST}",
    "port" => "",
    "db"   => "${MGA_DB_NAME}",
    "dsn"  => "",
    "pdoAttr" => array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8')
);
