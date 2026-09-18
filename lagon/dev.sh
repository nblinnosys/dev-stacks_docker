#!/usr/bin/env bash
# =============================================================================
# dev/lagon/dev.sh — stack de dev Lagon7 (PHP 7.4/Apache + MySQL 8 dédiée).
#   2 sites : public (lagon.localhost) + extranet (extranet.lagon.localhost).
#   Actions : up (défaut) | down | logs | url | reset | destroy
#   PAS de releases : code = clone git bind-monté (app/). Secrets = vault recette
#   (sinon secrets.env local). Base dédiée lagon_extranet (indépendante de mga).
#
# Méta (lue par menu.sh) :
#   name: lagon
#   desc: Lagon Courtage — site + extranet (PHP 7.4)
#   port: 8089
#   url:  http://lagon.localhost:8089/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

VAULT="${LAGON_VAULT:-$REC_ROOT/sites/lagon/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
ROLE_FILES="$REC_ROOT/sites/lagon/files"
APP_DIR="$SCRIPT_DIR/app"
GIT_URL_PATH="github.com/INNOSYSFRANCE/lagon7.git"
GIT_BRANCH="master"
WEB_PORT=8089
EXTRANET_PORT=8090
DB_NAME="lagon_extranet"
APP_CT="dev_lagon_web"
DB_CT="dev_lagon_db"
# Accès NORMAL via l'edge (pfSense -> Traefik) : 2 sous-domaines.
FQDN="lagon.${DEV_DOMAIN}"
EXT_FQDN="lagon-extranet.${DEV_DOMAIN}"
EXTRANET_URL="https://${EXT_FQDN}"
URL="https://${FQDN}/"
DIRECT_URL="http://${DEV_HOST}:${WEB_PORT}/"
DIRECT_EXT_URL="http://${DEV_HOST}:${EXTRANET_PORT}/"

cd "$SCRIPT_DIR"

secret(){
  local key="$1" val=""
  if [ -f "$VAULT" ]; then val="$(vault_get "$key" "$VAULT")"
  elif [ -f "$SECRETS_ENV" ]; then val="$( set -a; . "$SECRETS_ENV" >/dev/null 2>&1; printf '%s' "${!key-}" )"; fi
  printf '%s' "$val"
}

ensure_secrets_source(){
  if [ -f "$VAULT" ] || [ -f "$SECRETS_ENV" ]; then return; fi
  cat > "$SCRIPT_DIR/secrets.env.example" <<'EOF'
# Secrets Lagon7 dev (machine sans le dépôt). Copie en secrets.env et renseigne.
vault_github_token="ghp_xxx"
vault_lagon7_db_user="innodev"
vault_lagon7_db_password="CHANGE_ME"
vault_lagon7_db_root_password="CHANGE_ME"
vault_lagon7_recaptcha_publickey="CHANGE_ME"
vault_lagon7_recaptcha_privatekey="CHANGE_ME"
vault_lagon7_rollbar_token="CHANGE_ME"
EOF
  die "Aucune source de secrets. Dépôt recette absent ($VAULT).
   -> Remplis $SCRIPT_DIR/secrets.env (modèle : secrets.env.example) ou LAGON_VAULT."
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then info "Clone déjà présent (app/) — pas de git pull auto."; return; fi
  local tok; tok="$(secret vault_github_token)"; [ -n "$tok" ] || die "vault_github_token vide"
  info "Clone de INNOSYSFRANCE/lagon7 (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
}

generate_config(){
  local dbu dbp dbr
  dbu="$(secret vault_lagon7_db_user)"; dbp="$(secret vault_lagon7_db_password)"; dbr="$(secret vault_lagon7_db_root_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] || die "Identifiants DB Lagon absents (vault/secrets.env)"

  cat > "$SCRIPT_DIR/.env" <<EOF
PROJECT_NAME=lagon7
DB_HOST=lagon_db
DB_NAME=$DB_NAME
DB_USER=$dbu
DB_PASSWORD=$dbp
DB_ROOT_PASSWORD=$dbr
LAGON_HOST=$FQDN
LAGON_EXT_HOST=$EXT_FQDN
EOF

  export LAGON_DB_HOST="lagon_db" LAGON_DB_USER="$dbu" LAGON_DB_PASS="$dbp" LAGON_DB_NAME="$DB_NAME"
  export LAGON_RECAPTCHA_PUB="$(secret vault_lagon7_recaptcha_publickey)" LAGON_RECAPTCHA_PRIV="$(secret vault_lagon7_recaptcha_privatekey)"
  export LAGON_EXTRANET_URL="$EXTRANET_URL" LAGON_ROLLBAR_TOKEN="$(secret vault_lagon7_rollbar_token)" LAGON_ENV="dev"

  local spec='${LAGON_DB_HOST} ${LAGON_DB_USER} ${LAGON_DB_PASS} ${LAGON_DB_NAME} ${LAGON_RECAPTCHA_PUB} ${LAGON_RECAPTCHA_PRIV} ${LAGON_EXTRANET_URL} ${LAGON_ROLLBAR_TOKEN} ${LAGON_ENV}'
  require envsubst
  mkdir -p "$APP_DIR/extranet/secure/php" "$APP_DIR/extranet/include/Editor-PHP-1.6.5/php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/constants.php"     > "$APP_DIR/extranet/secure/php/constants.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/config.php"        > "$APP_DIR/extranet/include/config.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/inno_cn.php"       > "$APP_DIR/extranet/include/inno_cn.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/mondial_cn.php"    > "$APP_DIR/extranet/include/mondial_cn.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/editor_config.php" > "$APP_DIR/extranet/include/Editor-PHP-1.6.5/php/config.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/rollbar.php"       > "$APP_DIR/extranet/include/rollbar.php"
  ok "Config PHP générée (6 fichiers extranet)"
}

seed_dump(){
  mkdir -p "$SCRIPT_DIR/db/import"
  [ -f "$SCRIPT_DIR/db/import/lagon_extranet.sql" ] && return
  if [ -f "$ROLE_FILES/database/lagon_extranet.sql" ]; then cp "$ROLE_FILES/database/lagon_extranet.sql" "$SCRIPT_DIR/db/import/"
  else warn "Dump lagon_extranet.sql absent -> base créée vide"; fi
}

seed_theme(){
  local theme=""
  [ -f "$SCRIPT_DIR/assets.tar.gz" ] && theme="$SCRIPT_DIR/assets.tar.gz"
  [ -z "$theme" ] && [ -f "$ROLE_FILES/assets.tar.gz" ] && theme="$ROLE_FILES/assets.tar.gz"
  local a="$APP_DIR/extranet/assets"
  if [ -L "$a" ] || { [ -e "$a" ] && [ ! -d "$a" ]; }; then rm -f "$a"; fi
  if [ -d "$APP_DIR/extranet/assets/global" ]; then return; fi
  if [ -n "$theme" ]; then info "Extraction du thème Metronic (assets.tar.gz)…"; tar xzf "$theme" -C "$APP_DIR/extranet/"
  else warn "assets.tar.gz introuvable -> thème absent (copie-le dans dev/lagon/ ou le dépôt recette)"; fi
}

prepare_app(){
  # twig < 3.5 (compat PHP 7.4), release/clone uniquement
  local cj="$APP_DIR/extranet/composer.json"
  [ -f "$cj" ] && grep -q '"twig/twig"[[:space:]]*:[[:space:]]*"\^3\.2"' "$cj" && \
    sed -i 's#"twig/twig"[[:space:]]*:[[:space:]]*"\^3\.2"#"twig/twig": ">=3.2 <3.5"#' "$cj" || true
  # liens extranet PROD codés en dur -> domaine dev
  info "Repointage des liens extranet PROD -> $EXTRANET_URL…"
  local f
  for f in $(grep -rl 'https://extranet\.lagon-courtage\.fr' "$APP_DIR" --include='*.php' --include='*.html' --include='*.tpl' --include='*.phtml' 2>/dev/null || true); do
    sed -i "s#https://extranet\.lagon-courtage\.fr#$EXTRANET_URL#g" "$f"
  done
  # dossiers d'écriture de l'extranet
  mkdir -p "$APP_DIR/extranet/cron/factures" "$APP_DIR/extranet/cron/tva" \
           "$APP_DIR/extranet/cron/mondial" "$APP_DIR/extranet/cron/ams/retour/OK" \
           "$APP_DIR/extranet/cron/ams/retour/archives" "$APP_DIR/extranet/documents"
}

db_exec(){ docker exec "$DB_CT" sh -c "mysql -h 127.0.0.1 -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $*"; }

import_if_empty(){
  local dump="$SCRIPT_DIR/db/import/lagon_extranet.sql" n
  [ -f "$dump" ] || return 0
  n="$(db_exec "-N -B -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';\"" 2>/dev/null || echo 0)"
  if [ "${n:-0}" -eq 0 ]; then
    info "Import lagon_extranet.sql…"
    docker exec -i "$DB_CT" sh -c "mysql -h 127.0.0.1 -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $DB_NAME" < "$dump"
  else info "Base déjà peuplée ($n tables) -> import ignoré"; fi
}

app_bootstrap(){
  info "composer install (extranet/, twig<3.5)…"
  docker exec -e COMPOSER_ALLOW_SUPERUSER=1 -w /var/www/html/current/extranet "$APP_CT" \
    composer install --no-interaction --no-dev --optimize-autoloader || warn "composer a signalé une erreur"
  info "Droits d'écriture…"
  docker exec "$APP_CT" sh -c 'chmod -R a+rwX /var/www/html/current' || true
}

up(){
  require docker; require git; require envsubst
  ensure_secrets_source
  ensure_traefik_net
  clone_app
  generate_config
  seed_dump
  seed_theme
  prepare_app
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  wait_mysql "$DB_CT"
  import_if_empty
  app_bootstrap
  echo
  ok "Lagon7 dev prêt :"
  echo "     • Site public (edge)  : ${c_bold}${URL}${c_reset}"
  echo "     • Extranet   (edge)  : ${c_bold}${EXTRANET_URL}/${c_reset}"
  echo "     • Direct (debug)     : ${DIRECT_URL}  |  ${DIRECT_EXT_URL}"
  info "BDD locale (DBeaver) : ${DEV_HOST}:3318  base $DB_NAME"
}

down(){  info "Arrêt Lagon7 dev…"; dc down; ok "Arrêté (données conservées)"; }
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
