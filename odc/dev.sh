#!/usr/bin/env bash
# =============================================================================
# dev/odc/dev.sh — stack de dev ODC (Œuvre des Campagnes, Laravel/Backpack).
#   Actions : up (défaut) | down | logs | url | reset
#   PAS de releases : le code est un clone git bind-monté (édition live).
#   Secrets lus dans le vault recette (source unique) : sites/odc/vault.yml.
#
# Méta (lue par menu.sh) :
#   name: odc
#   desc: Œuvre des Campagnes — Laravel/Backpack (PHP 8.1)
#   port: 8443
#   url:  https://localhost:8443/login
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

# --- Paramètres du site --------------------------------------------------------
# Secrets : vault recette si le dépôt est à côté (ODC_VAULT pour forcer un chemin),
# sinon fichier local secrets.env (machine de dev autonome, sans le dépôt).
VAULT="${ODC_VAULT:-$REC_ROOT/sites/odc/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
DUMP_SRC="${ODC_DUMP:-$REC_ROOT/sites/odc/files/database/oeuvre_des_campagnes.sql}"
DUMP_DST="$SCRIPT_DIR/db/import/oeuvre_des_campagnes.sql"
APP_DIR="$SCRIPT_DIR/app"
GIT_URL_PATH="github.com/INNOSYSFRANCE/odc.git"
GIT_BRANCH="main"
WEB_PORT=8443
DB_NAME="oeuvre_des_campagnes"
APP_CT="dev_odc_app"
DB_CT="dev_odc_db"
# Accès NORMAL via l'edge (pfSense -> Traefik) : https://odc.<domaine>.
# APP_URL sert de base aux assets Backpack -> doit être le FQDN public.
FQDN="odc.${DEV_DOMAIN}"
APP_URL="https://${FQDN}"
URL="${APP_URL}/login"
# Accès direct (debug) TLS auto-signé sur le port publié.
DIRECT_URL="https://${DEV_HOST}:${WEB_PORT}/login"

cd "$SCRIPT_DIR"

# --- Lecture d'un secret : vault recette si présent, sinon secrets.env local ---
#   secrets.env utilise les MÊMES noms de clés (vault_odc_*, vault_github_token).
secret(){
  local key="$1" val=""
  if [ -f "$VAULT" ]; then
    val="$(vault_get "$key" "$VAULT")"
  elif [ -f "$SECRETS_ENV" ]; then
    val="$( set -a; . "$SECRETS_ENV" >/dev/null 2>&1; printf '%s' "${!key-}" )"
  fi
  printf '%s' "$val"
}

# --- Vérifie qu'une source de secrets existe ; sinon crée un modèle et sort -----
ensure_secrets_source(){
  if [ -f "$VAULT" ] || [ -f "$SECRETS_ENV" ]; then return; fi
  cat > "$SCRIPT_DIR/secrets.env.example" <<'EOF'
# Secrets ODC dev (machine sans le dépôt Innosys_global_rec_prod).
# Copie ce fichier en secrets.env et renseigne les valeurs (mêmes noms que le vault).
vault_github_token="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
vault_odc_db_user="innosys"
vault_odc_db_password="CHANGE_ME"
vault_odc_db_root_password="CHANGE_ME"
vault_odc_app_key="base64:CHANGE_ME"
vault_odc_backpack_user="CHANGE_ME"
vault_odc_backpack_password="CHANGE_ME"
vault_odc_default_pwd="CHANGE_ME"
vault_odc_qbo_client_id="CHANGE_ME"
vault_odc_qbo_client_secret="CHANGE_ME"
EOF
  die "Aucune source de secrets. Le dépôt recette n'est pas là ($VAULT).
   -> Remplis $SCRIPT_DIR/secrets.env  (modèle créé : secrets.env.example)
      ou lance depuis une machine où Innosys_global_rec_prod/ est à côté de dev/,
      ou exporte ODC_VAULT=/chemin/vers/vault.yml"
}

# --- Génération .env (compose) + app/.env (Laravel) + auth.json ---------------
generate_config(){
  local tok dbu dbp dbr appkey bpu bpp defpwd qid qsec
  tok="$(secret vault_github_token)"
  dbu="$(secret vault_odc_db_user)"
  dbp="$(secret vault_odc_db_password)"
  dbr="$(secret vault_odc_db_root_password)"
  appkey="$(secret vault_odc_app_key)"
  bpu="$(secret vault_odc_backpack_user)"
  bpp="$(secret vault_odc_backpack_password)"
  defpwd="$(secret vault_odc_default_pwd)"
  qid="$(secret vault_odc_qbo_client_id)"
  qsec="$(secret vault_odc_qbo_client_secret)"
  [ -n "$tok" ] || die "vault_github_token vide dans $VAULT"
  [ -n "$bpu" ] && [ -n "$bpp" ] || warn "Identifiants Backpack absents -> composer peut échouer sur backpack/pro"

  # .env lu par docker-compose (interpolation du service odc_db + label Traefik)
  cat > "$SCRIPT_DIR/.env" <<EOF
DB_ROOT_PASSWORD=$dbr
DB_DATABASE=$DB_NAME
DB_USERNAME=$dbu
DB_PASSWORD=$dbp
ODC_HOST=$FQDN
EOF

  # .env Laravel (dans le clone, bind-monté)
  cat > "$APP_DIR/.env" <<EOF
APP_NAME="Oeuvre des Campagnes (DEV)"
APP_ENV=dev
APP_KEY=$appkey
APP_DEBUG=true
APP_URL=$APP_URL

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=odc_db
DB_PORT=3306
DB_DATABASE=$DB_NAME
DB_USERNAME=$dbu
DB_PASSWORD=$dbp

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Mail : "log" en dev -> aucun envoi réel (mails écrits dans laravel.log)
MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=1025
MAIL_FROM_ADDRESS="ODC@innosys.fr"
MAIL_FROM_NAME="Oeuvre des Campagnes (DEV)"
MAIL_DEV="mvolet@innosys.fr"

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

ROLLBAR_TOKEN=37159b27b0c94eb09249cd485a32da77
MAX_FILE_UPLOAD=300
DEFAULTPWD="$defpwd"

QBO_CLIENT_ID="$qid"
QBO_CLIENT_SECRET="$qsec"
QBO_SANDBOX="true"
QBO_REDIRECT_URL="https://developer.intuit.com/v2/OAuth2Playground/RedirectUrl"
EOF

  # auth.json (Backpack http-basic + github-oauth) pour composer
  cat > "$APP_DIR/auth.json" <<EOF
{
    "http-basic": {
        "backpackforlaravel.com": { "username": "$bpu", "password": "$bpp" }
    },
    "github-oauth": { "github.com": "$tok" }
}
EOF
  ok "Config générée (.env compose + app/.env + auth.json)"
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then
    info "Clone déjà présent (app/) — édition live, pas de git pull automatique."
    return
  fi
  local tok; tok="$(secret vault_github_token)"
  [ -n "$tok" ] || die "vault_github_token vide -> clone impossible"
  info "Clone de INNOSYSFRANCE/odc (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
  ok "Dépôt cloné dans app/"
}

seed_dump(){
  mkdir -p "$SCRIPT_DIR/db/import"
  if [ -f "$DUMP_DST" ]; then return; fi
  [ -f "$DUMP_SRC" ] || { warn "Dump recette introuvable ($DUMP_SRC) — base démarrée vide"; return; }
  info "Copie du dump recette -> db/import/"
  cp "$DUMP_SRC" "$DUMP_DST"
}

import_if_empty(){
  local n
  n="$(docker exec "$DB_CT" sh -c 'mysql -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=\"'"$DB_NAME"'\"" 2>/dev/null' || echo 0)"
  if [ "${n:-0}" -eq 0 ]; then
    if [ -f "$DUMP_DST" ]; then
      info "Base vide -> import du dump ($(basename "$DUMP_DST"))…"
      docker exec -i "$DB_CT" sh -c 'mysql -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" '"$DB_NAME" < "$DUMP_DST"
      ok "Dump importé"
    else
      warn "Base vide et aucun dump -> migrate créera le schéma"
    fi
  else
    info "Base déjà peuplée ($n tables) -> import ignoré"
  fi
}

app_bootstrap(){
  info "composer install…"
  docker exec -w /var/www/html/odc "$APP_CT" composer install --no-interaction --prefer-dist --optimize-autoloader
  # ⚠ Bind-mount dev : on ne fait PAS chown du code (sinon .env devient illisible
  # côté hôte). On rend seulement inscriptibles les dossiers où Laravel écrit.
  info "Droits d'écriture storage/ + bootstrap/cache…"
  docker exec -w /var/www/html/odc "$APP_CT" sh -c 'chmod -R a+rwX storage bootstrap/cache'
  # APP_KEY absente (secrets.env non renseigné) -> on la génère (root peut écrire .env).
  if grep -q '^APP_KEY=$' "$APP_DIR/.env" 2>/dev/null; then
    info "APP_KEY vide -> php artisan key:generate…"
    docker exec -w /var/www/html/odc "$APP_CT" php artisan key:generate --force || true
  fi
  info "artisan migrate / storage:link / caches…"
  docker exec -w /var/www/html/odc "$APP_CT" php artisan migrate --force || warn "migrate a signalé une erreur (dump désaligné ?) — on continue"
  docker exec -w /var/www/html/odc "$APP_CT" php artisan storage:link || true
  docker exec -w /var/www/html/odc "$APP_CT" php artisan optimize:clear || true
  docker exec -w /var/www/html/odc "$APP_CT" sh -c 'chmod -R a+rwX storage bootstrap/cache' || true
}

# --- Actions -------------------------------------------------------------------
up(){
  require docker; require git
  ensure_secrets_source
  ensure_traefik_net
  clone_app
  generate_config
  seed_dump
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  wait_mysql "$DB_CT"
  import_if_empty
  app_bootstrap
  echo
  ok "ODC dev prêt :"
  echo "     • Via l'edge (Traefik) : ${c_bold}${URL}${c_reset}"
  echo "     • Accès direct (debug) : ${DIRECT_URL}  (cert auto-signé)"
  info "BDD locale (DBeaver) : ${DEV_HOST}:3316  base $DB_NAME"
}

down(){  info "Arrêt ODC dev…"; dc down; ok "Arrêté (données conservées)"; }
logs(){  dc logs -f --tail=100; }
url(){   echo "$URL"; open_url "$URL"; }
reset(){
  warn "Réinitialisation : suppression des conteneurs ET du volume BDD."
  dc down -v
  ok "Volume BDD supprimé. Relance 'up' pour repartir du dump."
}

case "${1:-up}" in
  up|deploy) up ;;
  down|stop) down ;;
  logs)      logs ;;
  url|open)  url ;;
  reset)     reset ;;
  destroy|purge) stack_destroy ;;
  *) die "Action inconnue : $1  (up|down|logs|url|reset|destroy)" ;;
esac
