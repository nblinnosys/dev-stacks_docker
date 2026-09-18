#!/bin/bash
# =============================================================================
# Init MySQL du pôle assurmix (portomix_data) — exécuté UNE SEULE FOIS au 1er
# démarrage (datadir vide), par l'entrypoint MySQL (/docker-entrypoint-initdb.d).
# Si le volume existe déjà, MySQL saute ce script -> pas de réimport / écrasement.
# Crée chaque base + importe son dump /dumps/<base>.sql[.gz], puis accorde les
# droits à l'utilisateur applicatif sur toutes les bases.
# =============================================================================
DBS="assurmix assurfranchise assurkids assurpret assurski assursport assurveto"
MYSQL="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"

for db in $DBS; do
  echo "[init] ${db} : création de la base"
  $MYSQL -e "CREATE DATABASE IF NOT EXISTS \`${db}\` CHARACTER SET utf8 COLLATE utf8_general_ci;"
  if [ -f "/dumps/${db}.sql" ]; then
    echo "[init] ${db} : import de /dumps/${db}.sql"
    $MYSQL "${db}" < "/dumps/${db}.sql"
  elif [ -f "/dumps/${db}.sql.gz" ]; then
    echo "[init] ${db} : import de /dumps/${db}.sql.gz"
    gunzip -c "/dumps/${db}.sql.gz" | $MYSQL "${db}"
  else
    echo "[init] !! aucun dump pour ${db} (/dumps/${db}.sql[.gz]) -> base vide"
  fi
done

echo "[init] octroi des droits à '${MYSQL_USER}' sur toutes les bases"
$MYSQL -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
echo "[init] terminé"
