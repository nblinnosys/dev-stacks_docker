#!/usr/bin/env bash
# =============================================================================
# dev/portomix/dev.sh — Portomix (PHP 7.4/Apache) — portail public du pôle assurmix.
#   Actions : up (défaut) | down | logs | url | reset | destroy
#   PAS de base à lui : se connecte à portomix_data (dev/base_assur_port_crmix, réseau assurenv).
#   `up` démarre la base partagée au besoin (ensure_shared_db) — sans la reconstruire
#   si elle existe déjà.
#
# Méta (menu.sh) :
#   name: portomix
#   desc: Assurmix — portail public (PHP 7.4) [base partagée]
#   port: 8091
#   url:  http://localhost:8091/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

VAULT="${PORTOMIX_VAULT:-$REC_ROOT/sites/portomix/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
APP_DIR="$SCRIPT_DIR/app"
GIT_URL_PATH="github.com/INNOSYSFRANCE/Portomix2025.git"
GIT_BRANCH="master"
WEB_PORT=8091
APP_CT="dev_portomix_site"
FQDN="assurmix.${DEV_DOMAIN}"
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
# Secrets Portomix dev. Copie en secrets.env. Les creds DB = ceux de portomix_data.
vault_github_token="ghp_xxx"
vault_portomix_db_user="innosys"
vault_portomix_db_password="CHANGE_ME"
vault_portomix_db_root_password="CHANGE_ME"
EOF
  die "Aucune source de secrets. Remplis $SECRETS_ENV (modèle : secrets.env.example) ou PORTOMIX_VAULT."
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then info "Clone déjà présent (app/) — pas de git pull auto."; return; fi
  local tok; tok="$(secret vault_github_token)"; [ -n "$tok" ] || die "vault_github_token vide"
  info "Clone de INNOSYSFRANCE/Portomix2025 (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
}

generate_config(){
  local dbu dbp
  dbu="$(secret vault_portomix_db_user)"; dbp="$(secret vault_portomix_db_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] || die "Identifiants DB portomix absents (vault/secrets.env)"
  printf 'PORTOMIX_HOST=%s\n' "$FQDN" > "$SCRIPT_DIR/.env"
  export PORTO_DB_USER="$dbu" PORTO_DB_PASS="$dbp" PORTO_SITE_URL="$URL"
  # SITE_URL sans slash final (le tpl ajoute les chemins)
  export PORTO_SITE_URL="https://${FQDN}"
  require envsubst
  mkdir -p "$APP_DIR/include"
  envsubst '${PORTO_DB_USER} ${PORTO_DB_PASS} ${PORTO_SITE_URL}' < "$SCRIPT_DIR/tpl/config.php" > "$APP_DIR/include/config.php"
  ok "Config générée (include/config.php)"
}

app_bootstrap(){
  info "composer install…"
  docker exec -e COMPOSER_ALLOW_SUPERUSER=1 -w /var/www/html/portomix "$APP_CT" \
    composer install --no-interaction --no-dev --optimize-autoloader || warn "composer a signalé une erreur"
  info "Droits d'écriture…"
  docker exec "$APP_CT" sh -c 'chmod -R a+rwX /var/www/html/portomix' || true
}

up(){
  require docker; require git; require envsubst
  ensure_secrets_source
  ensure_shared_db          # base partagée portomix_data (démarrée si absente)
  ensure_traefik_net
  clone_app
  generate_config
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  app_bootstrap
  echo
  ok "Portomix dev prêt :"
  echo "     • Via l'edge (Traefik) : ${c_bold}${URL}${c_reset}"
  echo "     • Accès direct (debug) : ${DIRECT_URL}"
  info "Base partagée : portomix_data (assurenv) — DBeaver ${DEV_HOST}:3307, base assurmix"
}

down(){  info "Arrêt Portomix dev…"; dc down; ok "Arrêté (base partagée conservée)"; }
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
