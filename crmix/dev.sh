#!/usr/bin/env bash
# =============================================================================
# dev/crmix/dev.sh — CRMIX (PHP 7.3/Apache, Symfony/InnoCore) — CRM du pôle assurmix.
#   Actions : up (défaut) | down | logs | url | reset | destroy
#   PAS de base à lui : se connecte à portomix_data (dev/base_assur_port_crmix, réseau assurenv).
#   Sous-domaine dédié. InnoCore installé via HTTPS+token (pas de clé SSH en dev).
#
# Méta (menu.sh) :
#   name: crmix
#   desc: CRMix — CRM Symfony/InnoCore (PHP 7.3) [base partagée]
#   port: 8093
#   url:  http://localhost:8093/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

VAULT="${CRMIX_VAULT:-$REC_ROOT/sites/crmix/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
ROLE_FILES="$REC_ROOT/sites/crmix/files"
APP_DIR="$SCRIPT_DIR/app"
THEME_DIR="$SCRIPT_DIR/theme"
GIT_URL_PATH="github.com/INNOSYSFRANCE/CRMix.git"
GIT_BRANCH="master"
WEB_PORT=8093
APP_CT="dev_crmix_site"
FQDN="crmix.${DEV_DOMAIN}"
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
# Secrets CRMIX dev. Copie en secrets.env. Creds DB = ceux de portomix_data.
vault_github_token="ghp_xxx"
vault_crmix_db_user="innosys"
vault_crmix_db_password="CHANGE_ME"
vault_crmix_rollbar_server=""
vault_crmix_rollbar_js=""
vault_crmix_seyna_portfolio_dev=""
vault_crmix_seyna_portfolio_prod=""
vault_crmix_seyna_auth_pwd=""
vault_crmix_seyna_api_key=""
EOF
  die "Aucune source de secrets. Remplis $SECRETS_ENV (modèle : secrets.env.example) ou CRMIX_VAULT."
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then info "Clone déjà présent (app/) — pas de git pull auto."; return; fi
  local tok; tok="$(secret vault_github_token)"; [ -n "$tok" ] || die "vault_github_token vide"
  info "Clone de INNOSYSFRANCE/CRMix (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
}

seed_theme(){
  local tarball=""
  [ -f "$SCRIPT_DIR/metronic_v4.7.5.tar.gz" ] && tarball="$SCRIPT_DIR/metronic_v4.7.5.tar.gz"
  [ -z "$tarball" ] && [ -f "$ROLE_FILES/metronic_v4.7.5.tar.gz" ] && tarball="$ROLE_FILES/metronic_v4.7.5.tar.gz"
  mkdir -p "$THEME_DIR"
  if [ -d "$THEME_DIR/metronic_v4.7.5/theme/assets" ]; then return; fi
  if [ -n "$tarball" ]; then info "Extraction du thème Metronic…"; tar xzf "$tarball" -C "$THEME_DIR/"
  else warn "metronic_v4.7.5.tar.gz introuvable -> thème absent (copie-le dans dev/crmix/ ou le dépôt recette)"; fi
}

generate_config(){
  local dbu dbp
  dbu="$(secret vault_crmix_db_user)"; dbp="$(secret vault_crmix_db_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] || die "Identifiants DB crmix absents (vault/secrets.env)"
  printf 'CRMIX_HOST=%s\n' "$FQDN" > "$SCRIPT_DIR/.env"
  export CRMIX_DB_USER="$dbu" CRMIX_DB_PASS="$dbp"
  export CRMIX_TOKEN="$(secret vault_github_token)"
  export CRMIX_ROLLBAR_SERVER="$(secret vault_crmix_rollbar_server)" CRMIX_ROLLBAR_JS="$(secret vault_crmix_rollbar_js)"
  export CRMIX_SEYNA_PORTFOLIO_DEV="$(secret vault_crmix_seyna_portfolio_dev)" CRMIX_SEYNA_PORTFOLIO_PROD="$(secret vault_crmix_seyna_portfolio_prod)"
  export CRMIX_SEYNA_AUTH_PWD="$(secret vault_crmix_seyna_auth_pwd)" CRMIX_SEYNA_API_KEY="$(secret vault_crmix_seyna_api_key)"
  local spec='${CRMIX_DB_USER} ${CRMIX_DB_PASS} ${CRMIX_TOKEN} ${CRMIX_ROLLBAR_SERVER} ${CRMIX_ROLLBAR_JS} ${CRMIX_SEYNA_PORTFOLIO_DEV} ${CRMIX_SEYNA_PORTFOLIO_PROD} ${CRMIX_SEYNA_AUTH_PWD} ${CRMIX_SEYNA_API_KEY}'
  require envsubst
  envsubst "$spec" < "$SCRIPT_DIR/tpl/env" > "$APP_DIR/.env"
  # dossiers d'écriture (best-effort)
  ( cd "$APP_DIR" && mkdir -p documents tmp/cache/twig tmp/exports tmp/upload )
  ok "Config générée (.env)"
}

app_bootstrap(){
  local tok; tok="$(secret vault_github_token)"
  info "composer install (InnoCore via HTTPS+token)…"
  docker exec -e GITHUB_TOKEN="$tok" -e COMPOSER_ALLOW_SUPERUSER=1 -w /var/www/html/current "$APP_CT" sh -lc '
    composer config -g github-oauth.github.com "$GITHUB_TOKEN"
    git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
    git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"
    git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "innocoregithub:"
    sed -i "s#git@github.com:#https://github.com/#g; s#innocoregithub:#https://github.com/#g" composer.json composer.lock 2>/dev/null || true
    composer install --no-dev --no-interaction --optimize-autoloader
  ' || warn "composer a signalé une erreur (InnoCore ? scripts Symfony ?)"
  info "Droits d'écriture…"
  docker exec "$APP_CT" sh -c 'chmod -R a+rwX /var/www/html/current' || true
}

up(){
  require docker; require git; require envsubst
  ensure_secrets_source
  ensure_shared_db
  ensure_traefik_net
  clone_app
  seed_theme
  generate_config
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  app_bootstrap
  echo
  ok "CRMix dev prêt :"
  echo "     • Via l'edge (Traefik) : ${c_bold}${URL}${c_reset}"
  echo "     • Accès direct (debug) : ${DIRECT_URL}"
  info "Base partagée : portomix_data (assurenv), base assurmix."
}

down(){  info "Arrêt CRMix dev…"; dc down; ok "Arrêté (base partagée conservée)"; }
logs(){  dc logs -f --tail=100; }
url(){   echo "$URL"; open_url "$URL"; }
reset(){ warn "Suppression du conteneur web (la base partagée n'est PAS touchée)."; dc down; ok "Fait."; }

case "${1:-up}" in
  up|deploy) up ;;
  down|stop) down ;;
  logs)      logs ;;
  url|open)  url ;;
  reset)     reset ;;
  destroy|purge) stack_destroy ;;
  *) die "Action inconnue : $1 (up|down|logs|url|reset|destroy)" ;;
esac
