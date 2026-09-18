#!/usr/bin/env bash
# =============================================================================
# dev/mga/dev.sh — stack de dev MGA « Ma Garantie Auto » (PHP 8.2/Apache + MySQL 8).
#   Actions : up (défaut) | down | logs | url | reset
#   PAS de releases : code = clone git bind-monté (app/). Secrets lus dans le vault
#   recette (sinon secrets.env local). Le réseau `mga` est partagé avec mga_vitrine.
#
# Méta (lue par menu.sh) :
#   name: mga
#   desc: Ma Garantie Auto — appli/back-office (PHP 8.2)
#   port: 8087
#   url:  http://localhost:8087/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

VAULT="${MGA_VAULT:-$REC_ROOT/sites/mga/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
ROLE_FILES="$REC_ROOT/sites/mga/files"
APP_DIR="$SCRIPT_DIR/app"
GIT_URL_PATH="github.com/INNOSYSFRANCE/mga.git"
GIT_BRANCH="master"
WEB_PORT=8087
APP_CT="dev_mga_web"
DB_CT="dev_mga_db"
MAIN_DB="mga_mb"
VITRINE_DB="mga_vitrine"
LAGON_DB="lagon_extranet"
# Accès NORMAL via l'edge (pfSense -> Traefik) : https://mga.<domaine>
FQDN="mga.${DEV_DOMAIN}"
URL="https://${FQDN}/"
DIRECT_URL="http://${DEV_HOST}:${WEB_PORT}/"

cd "$SCRIPT_DIR"

# --- Secret : vault recette si présent, sinon secrets.env local (mêmes clés) ---
secret(){
  local key="$1" val=""
  if [ -f "$VAULT" ]; then val="$(vault_get "$key" "$VAULT")"
  elif [ -f "$SECRETS_ENV" ]; then val="$( set -a; . "$SECRETS_ENV" >/dev/null 2>&1; printf '%s' "${!key-}" )"; fi
  printf '%s' "$val"
}

ensure_secrets_source(){
  if [ -f "$VAULT" ] || [ -f "$SECRETS_ENV" ]; then return; fi
  cat > "$SCRIPT_DIR/secrets.env.example" <<'EOF'
# Secrets MGA dev (machine sans le dépôt). Copie en secrets.env et renseigne.
vault_github_token="ghp_xxx"
vault_mga_db_user="innodev"
vault_mga_db_password="CHANGE_ME"
vault_mga_db_root_password="CHANGE_ME"
vault_mga_lagon_db_user="innodev"
vault_mga_lagon_db_password="CHANGE_ME"
vault_mga_rollbar_token="1111NOTOKEN111111111111111111111"
vault_mga_paybox_site="CHANGE_ME"
vault_mga_paybox_id="CHANGE_ME"
vault_mga_paybox_binkey="CHANGE_ME"
vault_mga_aaa_siret="CHANGE_ME"
vault_mga_aaa_name="CHANGE_ME"
vault_mga_aaa_password="CHANGE_ME"
vault_mga_recaptcha_publickey="CHANGE_ME"
vault_mga_recaptcha_privatekey="CHANGE_ME"
vault_mga_phpmailer_user="CHANGE_ME"
vault_mga_phpmailer_password="CHANGE_ME"
EOF
  die "Aucune source de secrets. Dépôt recette absent ($VAULT).
   -> Remplis $SCRIPT_DIR/secrets.env (modèle : secrets.env.example)
      ou lance là où Innosys_global_rec_prod/ est à côté de dev/ (MGA_VAULT pour forcer)."
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then info "Clone déjà présent (app/) — pas de git pull auto."; return; fi
  local tok; tok="$(secret vault_github_token)"; [ -n "$tok" ] || die "vault_github_token vide"
  info "Clone de INNOSYSFRANCE/mga (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
}

generate_config(){
  local dbu dbp dbr
  dbu="$(secret vault_mga_db_user)"; dbp="$(secret vault_mga_db_password)"; dbr="$(secret vault_mga_db_root_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] || die "Identifiants DB MGA absents (vault/secrets.env)"

  # .env compose (secrets MySQL)
  cat > "$SCRIPT_DIR/.env" <<EOF
PROJECT_NAME=mga
DB_HOST=mga_db
DB_NAME=$MAIN_DB
DB_USER=$dbu
DB_PASSWORD=$dbp
DB_ROOT_PASSWORD=$dbr
MGA_HOST=$FQDN
EOF

  # Variables pour envsubst (rendu des 4 fichiers de conf PHP)
  export MGA_DB_HOST="mga_db" MGA_DB_USER="$dbu" MGA_DB_PASS="$dbp" MGA_DB_NAME="$MAIN_DB" MGA_DB_VITRINE="$VITRINE_DB"
  export MGA_LAGON_HOST="mga_db" MGA_LAGON_NAME="$LAGON_DB" MGA_LAGON_USER="$dbu" MGA_LAGON_PASS="$dbp"
  export MGA_ENV="DEV" MGA_SERVER_URL="$URL"
  export MGA_PHPMAILER_USER="$(secret vault_mga_phpmailer_user)" MGA_PHPMAILER_PASS="$(secret vault_mga_phpmailer_password)"
  export MGA_ROLLBAR_TOKEN="$(secret vault_mga_rollbar_token)" MGA_ROLLBAR_ENV="DEV"
  export MGA_PAYBOX_SITE="$(secret vault_mga_paybox_site)" MGA_PAYBOX_ID="$(secret vault_mga_paybox_id)" MGA_PAYBOX_BINKEY="$(secret vault_mga_paybox_binkey)"
  export MGA_AAA_SIRET="$(secret vault_mga_aaa_siret)" MGA_AAA_NAME="$(secret vault_mga_aaa_name)" MGA_AAA_PASS="$(secret vault_mga_aaa_password)"
  export MGA_RECAPTCHA_PUB="$(secret vault_mga_recaptcha_publickey)" MGA_RECAPTCHA_PRIV="$(secret vault_mga_recaptcha_privatekey)"
  [ -n "$MGA_ROLLBAR_TOKEN" ] || export MGA_ROLLBAR_TOKEN="1111NOTOKEN111111111111111111111"

  local spec='${MGA_DB_HOST} ${MGA_DB_USER} ${MGA_DB_PASS} ${MGA_DB_NAME} ${MGA_DB_VITRINE} ${MGA_LAGON_HOST} ${MGA_LAGON_NAME} ${MGA_LAGON_USER} ${MGA_LAGON_PASS} ${MGA_ENV} ${MGA_SERVER_URL} ${MGA_PHPMAILER_USER} ${MGA_PHPMAILER_PASS} ${MGA_ROLLBAR_TOKEN} ${MGA_ROLLBAR_ENV} ${MGA_PAYBOX_SITE} ${MGA_PAYBOX_ID} ${MGA_PAYBOX_BINKEY} ${MGA_AAA_SIRET} ${MGA_AAA_NAME} ${MGA_AAA_PASS} ${MGA_RECAPTCHA_PUB} ${MGA_RECAPTCHA_PRIV}'

  require envsubst
  mkdir -p "$APP_DIR/secure/php" "$APP_DIR/includes/Editor-PHP-1.6.5/php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/constants.php" > "$APP_DIR/secure/php/constants.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/config.php"    > "$APP_DIR/includes/Editor-PHP-1.6.5/php/config.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/cn.php"        > "$APP_DIR/includes/cn.php"
  cp "$SCRIPT_DIR/tpl/rollbar.php" "$APP_DIR/includes/rollbar.php"
  ok "Config PHP générée (constants/config Editor/cn/rollbar)"
}

seed_dumps(){
  mkdir -p "$SCRIPT_DIR/db/import"
  local f
  for f in mga_mb.sql mga_vitrine.sql; do
    [ -f "$SCRIPT_DIR/db/import/$f" ] && continue
    if [ -f "$ROLE_FILES/database/$f" ]; then cp "$ROLE_FILES/database/$f" "$SCRIPT_DIR/db/import/$f"
    else warn "Dump $f absent (ni db/import/ ni $ROLE_FILES/database/) -> schéma créé vide"; fi
  done
}

seed_theme(){
  local theme=""
  [ -f "$SCRIPT_DIR/assets.tar.gz" ] && theme="$SCRIPT_DIR/assets.tar.gz"
  [ -z "$theme" ] && [ -f "$ROLE_FILES/assets.tar.gz" ] && theme="$ROLE_FILES/assets.tar.gz"
  # supprimer le symlink assets du repo (cible /var/www/theme absente)
  local a="$APP_DIR/assets"
  if [ -L "$a" ] || { [ -e "$a" ] && [ ! -d "$a" ]; }; then rm -f "$a"; fi
  if [ -d "$APP_DIR/assets/global" ]; then return; fi
  if [ -n "$theme" ]; then info "Extraction du thème Metronic (assets.tar.gz)…"; tar xzf "$theme" -C "$APP_DIR/"
  else warn "assets.tar.gz introuvable -> thème absent (copie-le dans dev/mga/ ou le dépôt recette)"; fi
}

db_exec(){ docker exec "$DB_CT" sh -c "mysql -h 127.0.0.1 -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $*"; }

db_setup(){
  local dbu; dbu="$(secret vault_mga_db_user)"
  info "Création des schémas mga_vitrine + lagon_extranet (vide) + droits…"
  db_exec "-e \"CREATE DATABASE IF NOT EXISTS $VITRINE_DB CHARACTER SET utf8 COLLATE utf8_general_ci;
                CREATE DATABASE IF NOT EXISTS $LAGON_DB CHARACTER SET utf8 COLLATE utf8_general_ci;
                GRANT ALL PRIVILEGES ON $VITRINE_DB.* TO '$dbu'@'%';
                GRANT ALL PRIVILEGES ON $LAGON_DB.*  TO '$dbu'@'%';
                FLUSH PRIVILEGES;\""
}

import_if_empty(){ # <schema> <dumpfile>
  local schema="$1" dump="$SCRIPT_DIR/db/import/$2" n
  [ -f "$dump" ] || return 0
  n="$(db_exec "-N -B -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$schema';\"" 2>/dev/null || echo 0)"
  if [ "${n:-0}" -eq 0 ]; then
    info "Import $2 -> $schema…"
    docker exec -i "$DB_CT" sh -c "mysql -h 127.0.0.1 -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $schema" < "$dump"
  else info "$schema déjà peuplé ($n tables) -> import ignoré"; fi
}

php8_patches(){
  info "Patches PHP 8 + repointage lagon (idempotents)…"
  local f
  f="$APP_DIR/includes/PHPMailer/PHPMailerAutoload.php"
  [ -f "$f" ] && grep -q '__autoload' "$f" && sed -i 's/__autoload/spl_autoload_register/g' "$f" || true
  f="$APP_DIR/includes/Editor-PHP-1.6.5/php/DataTables.php"
  [ -f "$f" ] && sed -i 's/define("DATATABLES", true, true);/define("DATATABLES", true, false);/' "$f" || true
  f="$APP_DIR/includes/Editor-PHP-1.6.5/php/Database/Database.php"
  [ -f "$f" ] && ! grep -q 'AllowDynamicProperties' "$f" && \
    sed -i 's/^class Database {/use AllowDynamicProperties;\n#[AllowDynamicProperties]\nclass Database {/' "$f" || true
  f="$APP_DIR/includes/Editor-PHP-1.6.5/php/Database/Driver/Mysql/Query.php"
  [ -f "$f" ] && ! grep -q 'AllowDynamicProperties' "$f" && \
    sed -i 's/^class DriverMysqlQuery extends Query {/use AllowDynamicProperties;\n#[AllowDynamicProperties]\nclass DriverMysqlQuery extends Query {/' "$f" || true
  f="$APP_DIR/src/Controller/AmsSameImaController.php"
  [ -f "$f" ] && sed -i "s/'mysql:host='\.DB_SERVER\.';dbname='\.DB_NAME_LAGON/'mysql:host='.DB_SERVER_LAGON.';dbname='.DB_NAME_LAGON/" "$f" || true
  f="$APP_DIR/src/Controller/ConnectionDatabaseLagonController.php"
  [ -f "$f" ] && sed -i "s/'mysql:dbname='\.DB_NAME_LAGON\.';host='\.DB_SERVER\.';charset=utf8'/'mysql:dbname='.DB_NAME_LAGON.';host='.DB_SERVER_LAGON.';charset=utf8'/" "$f" || true
}

app_bootstrap(){
  info "composer install…"
  docker exec -e COMPOSER_ALLOW_SUPERUSER=1 -w /var/www/html/current "$APP_CT" \
    composer install --no-interaction --prefer-dist --no-progress --optimize-autoloader || warn "composer a signalé une erreur"
  info "Droits d'écriture (uploads/exports)…"
  docker exec "$APP_CT" sh -c 'chmod -R a+rwX /var/www/html/current' || true
}

up(){
  require docker; require git; require envsubst
  ensure_secrets_source
  ensure_traefik_net
  clone_app
  generate_config
  seed_dumps
  seed_theme
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  wait_mysql "$DB_CT"
  db_setup
  import_if_empty "$MAIN_DB"    mga_mb.sql
  import_if_empty "$VITRINE_DB" mga_vitrine.sql
  php8_patches
  app_bootstrap
  echo
  ok "MGA dev prêt :"
  echo "     • Via l'edge (Traefik) : ${c_bold}${URL}${c_reset}"
  echo "     • Accès direct (debug) : ${DIRECT_URL}"
  info "BDD locale (DBeaver) : ${DEV_HOST}:3317  schémas $MAIN_DB + $VITRINE_DB (+ $LAGON_DB vide)"
}

down(){  info "Arrêt MGA dev…"; dc down; ok "Arrêté (données conservées)"; }
logs(){  dc logs -f --tail=100; }
url(){   echo "$URL"; open_url "$URL"; }
reset(){ warn "Suppression conteneurs + volume BDD."; dc down -v; ok "Volume BDD supprimé."; }

case "${1:-up}" in
  up|deploy) up ;;
  down|stop) down ;;
  logs)      logs ;;
  url|open)  url ;;
  reset)     reset ;;
  destroy|purge) stack_destroy ;;
  *) die "Action inconnue : $1 (up|down|logs|url|reset|destroy)" ;;
esac
