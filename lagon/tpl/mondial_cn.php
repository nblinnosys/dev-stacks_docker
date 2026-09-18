<?php
// Lagon7 DEV -> extranet/include/mondial_cn.php (généré via envsubst).
// MGA/Mondial neutralisé en dev : $bdd_inassur pointe sur la base LOCALE lagon.
$bdd_lagon = new PDO(
    'mysql:host=${LAGON_DB_HOST};dbname=${LAGON_DB_NAME}',
    '${LAGON_DB_USER}',
    '${LAGON_DB_PASS}'
);

$bdd_inassur = new PDO(
    'mysql:host=${LAGON_DB_HOST};dbname=${LAGON_DB_NAME}',
    '${LAGON_DB_USER}',
    '${LAGON_DB_PASS}'
);
?>
