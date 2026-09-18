<?php
/* MGA — secure/php/constants.php (DEV, généré par dev.sh via envsubst).
 * DB principale (mga_mb + mga_vitrine) = conteneur mga_db.
 * Lagon en dev = schéma vide lagon_extranet créé sur mga_db (DB_SERVER_LAGON=mga_db).
 * ENVIRONNEMENT=DEV -> mails redirigés vers MAIL_DEV, Paybox preprod. */

define("DB_SERVER", "${MGA_DB_HOST}");
define("DB_PASS",   "${MGA_DB_PASS}");
define("DB_NAME",   "${MGA_DB_NAME}");

define("DB_SERVER_LAGON",      "${MGA_LAGON_HOST}");
define("DB_NAME_LAGON",        "${MGA_LAGON_NAME}");
define("DB_USER_LAGON",        "${MGA_LAGON_USER}");
define("DB_PASS_LAGON",        "${MGA_LAGON_PASS}");
define("DB_NAME_MGA_VITRINE",  "${MGA_DB_VITRINE}");

define("ENVIRONNEMENT", '${MGA_ENV}');

define("SERVER_URL", "${MGA_SERVER_URL}");

/* liste des adresses mails en bcc des mails de relance automatique */
define("BCC_RELANCE", serialize(array(
  'MBragance Innosys' => 'mbragance@innosys.fr',
)));

/* liste des adresses mails en Add des mails du cron imatech */
define('ADD_CROM_IMATECH', serialize(array(
  ['email'=>'contact@gestionsinistre.fr','nom'=>'IMATECH_CENTRE-VALIDATION-TECHNIQUE'],
  ['email'=>'l.dabin@imatechnologies.fr','nom'=>'Lucas DABIN'],
  ['email'=>'g.roussel@imatechnologies.fr','nom'=>'Gwénaël ROUSSEL']
)));

/* liste des adresses mails en addbcc */
define('ADDBCC', serialize(array(
  ['email'=>'mbragance@innosys.fr', 'nom'=>'Mbragance Innosys'],
  ['email'=>'francois.salinier@inassur.fr', 'nom'=>'FSalinier Inassur'],
  ['email'=>'olivier.lavielle@inassur.fr', 'nom'=>'OLavielle Inassur'],
  ['email'=>'service-client@inassur.fr', 'nom'=>'Service Inassur'],
  ['email'=>'administration@inassur.fr', 'nom'=>'Administration Inasur'],
)));

/* liste des adresses mails en Add des mails du cron nettoyage ventes non validées */
define('ADD_CROM_NON_VALIDE', serialize(array(
  ['email'=>'mbragance@innosys.fr','nom'=>'Mbragance Innosys'],
  ['email'=>'fsalinier@innosys.fr','nom'=>'Fsalinier Innosys'],
)));

/* Connection php mailer  */
define("PHP_MAILER_USERNAME", "${MGA_PHPMAILER_USER}");
define("PHP_MAILER_PASSWORD", "${MGA_PHPMAILER_PASS}");

/* Connection Rollbar  */
define("ACCESS_TOKEN",         "${MGA_ROLLBAR_TOKEN}");
define("ENVIRONNEMENT_ROLLBAR","${MGA_ROLLBAR_ENV}");

/* Adresse Dev */
define("MAIL_DEV", serialize(array(
  ['email'=>'mbragance@innosys.fr', 'nom'=>'Mbragance Innosys']
)));

/* ID PAYBOX */
define("PBX_SITE",       '${MGA_PAYBOX_SITE}');
define("PBX_IDENTIFIANT","${MGA_PAYBOX_ID}");

// INFOS AAA DATA
define('N_SIRET',  '${MGA_AAA_SIRET}');
define('NOM_UTIL', '${MGA_AAA_NAME}');
define('MDP_UTIL', '${MGA_AAA_PASS}');

define('SERVEURS_PAYBOX' , (array(
  'serveur_primaire'   => 'tpe-preprod-tpeweb.paybox.com',
  'serveur_secondaire' => 'tpe-preprod-tpeweb.paybox.com'
)));

define('BINKEY', "${MGA_PAYBOX_BINKEY}");

define("GUEST_NAME", "Guest");
define("COOKIE_EXPIRE", 60*60*24*100);
define("COOKIE_PATH", "/");

define("EMAIL_FROM_NAME", "Ma Garantie Auto");
define("EMAIL_FROM_ADDR", "contact@magarantieauto.fr");

define("ALL_LOWERCASE", false);

define("supersecret_hash_padding",  'String used to pad out small strings for a sha1 encryption');
define("supersecret_hash_padding_2",'Other String used to pad out small strings for a sha1 encryption');

define("REPEAT_EMAIL", true);
define("REPEAT_PASSWORD", true);

$url = sprintf(
  "%s://%s",
  (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] != 'off')
    || (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')
    ? 'https' : 'http',
  $_SERVER['SERVER_NAME']
);
define("RESETPASSWORDLINK",  $url."/index.php?nav=pass_update");
define("CONFIRMACCOUNTLINK", $url."/index.php?nav=acc_confirm");

define("PUBLICKEY",  "${MGA_RECAPTCHA_PUB}");
define("PRIVATEKEY", "${MGA_RECAPTCHA_PRIV}");
?>
