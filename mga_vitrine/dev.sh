#!/usr/bin/env bash
# =============================================================================
# dev/mga_vitrine/dev.sh — vitrine publique MGA (PHP 7.4/Apache, code « raw »).
#   Actions : up (défaut) | down | logs | url | reset
#   PAS de base à elle : lit mga_vitrine sur le conteneur mga_db (dev/mga), via le
#   réseau externe `mga`. -> LANCER dev/mga AVANT. InnoCore installé via HTTPS+token.
#
# Méta (lue par menu.sh) :
#   name: mga_vitrine
#   desc: Ma Garantie Auto — vitrine publique (PHP 7.4) [lance mga d'abord]
#   port: 8088
#   url:  http://localhost:8088/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

VAULT="${MGAV_VAULT:-$REC_ROOT/sites/mga_vitrine/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
ROLE_FILES="$REC_ROOT/sites/mga_vitrine/files"
APP_DIR="$SCRIPT_DIR/app"
GIT_URL_PATH="github.com/INNOSYSFRANCE/mga-vitrine.git"
GIT_BRANCH="master"
WEB_PORT=8088
APP_CT="dev_mga_vitrine_web"
# Accès NORMAL via l'edge (pfSense -> Traefik) : https://mga-vitrine.<domaine>
FQDN="mga-vitrine.${DEV_DOMAIN}"
MGA_FQDN="mga.${DEV_DOMAIN}"
URL="https://${FQDN}/"
DIRECT_URL="http://${DEV_HOST}:${WEB_PORT}/"

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
# Secrets mga-vitrine dev (machine sans le dépôt). Copie en secrets.env et renseigne.
vault_github_token="ghp_xxx"
vault_mga_vitrine_db_user="innodev"
vault_mga_vitrine_db_password="CHANGE_ME"
vault_mga_vitrine_recaptcha_key="CHANGE_ME"
vault_mga_vitrine_recaptcha_secret="CHANGE_ME"
vault_mga_vitrine_shortpixel_api=""
vault_mga_vitrine_rollbar_token=""
vault_mga_vitrine_github_api_token=""
vault_mga_vitrine_mail_user="CHANGE_ME"
vault_mga_vitrine_mail_password="CHANGE_ME"
EOF
  die "Aucune source de secrets. Dépôt recette absent ($VAULT).
   -> Remplis $SCRIPT_DIR/secrets.env (modèle : secrets.env.example) ou MGAV_VAULT."
}

require_mga(){
  docker network inspect mga >/dev/null 2>&1 || \
    die "Réseau 'mga' absent -> lance d'abord dev/mga (./menu.sh -> mga -> Déployer)."
  docker ps --format '{{.Names}}' | grep -qx dev_mga_db || \
    warn "dev_mga_db non démarré -> la vitrine ne pourra pas lire la BDD. Lance dev/mga."
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then info "Clone déjà présent (app/) — pas de git pull auto."; return; fi
  local tok; tok="$(secret vault_github_token)"; [ -n "$tok" ] || die "vault_github_token vide"
  info "Clone de INNOSYSFRANCE/mga-vitrine (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
}

generate_config(){
  local dbu dbp
  dbu="$(secret vault_mga_vitrine_db_user)"; dbp="$(secret vault_mga_vitrine_db_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] || die "Identifiants DB vitrine absents (vault/secrets.env)"

  export MGAV_ENV="developpement" MGAV_THEME_PATH="/porto"
  export MGAV_SITE_URL="https://${FQDN}" MGAV_SITE_URL_IMAGE="https://${FQDN}"
  export MGAV_DEVIS_URL="https://${MGA_FQDN}/formulaire_souscription_marque_blanche.php"
  # .env compose (pour le label Traefik Host)
  printf 'MGAV_HOST=%s\n' "$FQDN" > "$SCRIPT_DIR/.env"
  export MGAV_ROLLBAR_TOKEN="$(secret vault_mga_vitrine_rollbar_token)"
  export MGAV_GITHUB_API_TOKEN="$(secret vault_mga_vitrine_github_api_token)"
  export MGAV_DB_HOST="mga_db" MGAV_DB_USER="$dbu" MGAV_DB_PASS="$dbp" MGAV_DB_NAME="mga_vitrine" MGAV_DB_NAME_MGA="mga_mb"
  export MGAV_MAIL_USER="$(secret vault_mga_vitrine_mail_user)" MGAV_MAIL_PASS="$(secret vault_mga_vitrine_mail_password)"
  export MGAV_MAIL_TO="mbragance@innosys.fr" MGAV_MAIL_HOST="smtp.office365.com" MGAV_MAIL_PORT="587"
  export MGAV_SHORTPIXEL="$(secret vault_mga_vitrine_shortpixel_api)"
  export MGAV_RECAPTCHA_KEY="$(secret vault_mga_vitrine_recaptcha_key)" MGAV_RECAPTCHA_SECRET="$(secret vault_mga_vitrine_recaptcha_secret)"

  local spec='${MGAV_ENV} ${MGAV_THEME_PATH} ${MGAV_SITE_URL} ${MGAV_SITE_URL_IMAGE} ${MGAV_DEVIS_URL} ${MGAV_ROLLBAR_TOKEN} ${MGAV_GITHUB_API_TOKEN} ${MGAV_DB_HOST} ${MGAV_DB_USER} ${MGAV_DB_PASS} ${MGAV_DB_NAME} ${MGAV_DB_NAME_MGA} ${MGAV_MAIL_USER} ${MGAV_MAIL_PASS} ${MGAV_MAIL_TO} ${MGAV_MAIL_HOST} ${MGAV_MAIL_PORT} ${MGAV_SHORTPIXEL} ${MGAV_RECAPTCHA_KEY} ${MGAV_RECAPTCHA_SECRET}'
  require envsubst
  mkdir -p "$APP_DIR/include"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/config.php" > "$APP_DIR/include/config.php"
  ok "Config générée (include/config.php)"
}

seed_theme(){
  local theme=""
  [ -f "$SCRIPT_DIR/porto.tar.gz" ] && theme="$SCRIPT_DIR/porto.tar.gz"
  [ -z "$theme" ] && [ -f "$ROLE_FILES/porto.tar.gz" ] && theme="$ROLE_FILES/porto.tar.gz"
  local p="$APP_DIR/porto"
  if [ -L "$p" ] || { [ -e "$p" ] && [ ! -d "$p" ]; }; then rm -f "$p"; fi
  if [ -d "$APP_DIR/porto/css" ]; then return; fi
  if [ -n "$theme" ]; then info "Extraction du thème Porto…"; tar xzf "$theme" -C "$APP_DIR/"
  else warn "porto.tar.gz introuvable -> thème absent (copie-le dans dev/mga_vitrine/ ou le dépôt recette)"; fi
}

app_bootstrap(){
  local tok; tok="$(secret vault_github_token)"
  # InnoCore est déclaré avec l'alias SSH `innocoregithub:` -> on réécrit l'URL en
  # HTTPS dans composer.json/lock (méthode du hook recette) + github-oauth token.
  # Aucun ssh requis (l'image dev n'a pas ssh-client).
  info "composer install (InnoCore via HTTPS+token, réécriture de l'URL)…"
  docker exec -e GITHUB_TOKEN="$tok" -e COMPOSER_ALLOW_SUPERUSER=1 -w /var/www/html/current "$APP_CT" sh -lc '
    composer config -g github-oauth.github.com "$GITHUB_TOKEN"
    sed -i "s#innocoregithub:#https://github.com/#g" composer.json composer.lock 2>/dev/null || true
    composer install --no-dev --no-interaction --optimize-autoloader
  ' || warn "composer a signalé une erreur (InnoCore ?)"
  info "Droits d'écriture…"
  docker exec "$APP_CT" sh -c 'chmod -R a+rwX /var/www/html/current' || true
}

up(){
  require docker; require git; require envsubst
  ensure_secrets_source
  ensure_traefik_net
  require_mga
  clone_app
  generate_config
  seed_theme
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  app_bootstrap
  echo
  ok "mga-vitrine dev prêt :"
  echo "     • Via l'edge (Traefik) : ${c_bold}${URL}${c_reset}"
  echo "     • Accès direct (debug) : ${DIRECT_URL}"
  info "Lit le schéma mga_vitrine sur dev_mga_db (réseau mga)."
}

down(){  info "Arrêt mga-vitrine dev…"; dc down; ok "Arrêté"; }
logs(){  dc logs -f --tail=100; }
url(){   echo "$URL"; open_url "$URL"; }
reset(){ warn "Suppression du conteneur (pas de volume propre)."; dc down; ok "Fait."; }

case "${1:-up}" in
  up|deploy) up ;;
  down|stop) down ;;
  logs)      logs ;;
  url|open)  url ;;
  reset)     reset ;;
  destroy|purge) stack_destroy ;;
  *) die "Action inconnue : $1 (up|down|logs|url|reset|destroy)" ;;
esac
