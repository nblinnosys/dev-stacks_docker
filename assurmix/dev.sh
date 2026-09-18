#!/usr/bin/env bash
# =============================================================================
# dev/assurmix/dev.sh — Assurmix (PHP 5.6/Apache) — back-office « pro » du pôle.
#   Actions : up (défaut) | down | logs | url | reset | destroy
#   PAS de base à lui : se connecte à portomix_data (dev/base_assur_port_crmix, réseau assurenv).
#   Servi sous /pro sur le MÊME domaine que portomix (Traefik PathPrefix, priorité >).
#
# Méta (menu.sh) :
#   name: assurmix
#   desc: Assurmix — back-office /pro (PHP 5.6) [base partagée]
#   port: 8092
#   url:  http://localhost:8092/pro/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ROOT="$(cd "$DEV_ROOT/.." && pwd)"
REC_ROOT="$DEPLOY_ROOT/Innosys_global_rec_prod"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

VAULT="${ASSURMIX_VAULT:-$REC_ROOT/sites/assurmix/vault.yml}"
SECRETS_ENV="$SCRIPT_DIR/secrets.env"
APP_DIR="$SCRIPT_DIR/app"
GIT_URL_PATH="github.com/INNOSYSFRANCE/assurmix.git"
GIT_BRANCH="master"
WEB_PORT=8092
APP_CT="dev_assurmix_site"
FQDN="assurmix.${DEV_DOMAIN}"
URL="https://${FQDN}/pro/"
DIRECT_URL="http://${DEV_HOST}:${WEB_PORT}/pro/"

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
# Secrets Assurmix dev. Copie en secrets.env. Creds DB = ceux de portomix_data.
vault_github_token="ghp_xxx"
vault_assurmix_db_user="innosys"
vault_assurmix_db_password="CHANGE_ME"
EOF
  die "Aucune source de secrets. Remplis $SECRETS_ENV (modèle : secrets.env.example) ou ASSURMIX_VAULT."
}

clone_app(){
  if [ -d "$APP_DIR/.git" ]; then info "Clone déjà présent (app/) — pas de git pull auto."; return; fi
  local tok; tok="$(secret vault_github_token)"; [ -n "$tok" ] || die "vault_github_token vide"
  info "Clone de INNOSYSFRANCE/assurmix (branche $GIT_BRANCH)…"
  git clone --branch "$GIT_BRANCH" "https://${tok}@${GIT_URL_PATH}" "$APP_DIR"
}

RUNTIME_DIRS="pro/secure/php pro/secure/script assurfranchise/secure/php assurance-de-pret/current/secure/php
 pro/tmp pro/documents/affiliations pro/documents/affiliations/franchise pro/documents/annulations
 pro/documents/annulations/aveto pro/documents/annulations/franchise pro/documents/attestation/akids
 pro/documents/attestation/annulation pro/documents/attestation/askisport pro/documents/attestation/aveto
 pro/documents/attestation/franchise pro/documents/crons pro/documents/echeanciers
 pro/documents/ecritures_comptables pro/documents/ecritures_comptables/sepa_public pro/documents/mandats
 pro/documents/mandats/franchise pro/documents/prelevements pro/documents/renouvellements
 pro/documents/sinistres/franchise pro/documents/signassur/assurveto pro/documents/xml_sepa/genere_par_adm
 pro/documents/mise_demeure pro/documents/relance pro/documents/vakario pro/factures
 pro/images/declaration_sinistre assurfranchise/documents/affiliations assurfranchise/documents/attestations
 assurfranchise/documents/tmp include/news/news_img"

generate_config(){
  local dbu dbp
  dbu="$(secret vault_assurmix_db_user)"; dbp="$(secret vault_assurmix_db_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] || die "Identifiants DB assurmix absents (vault/secrets.env)"
  printf 'ASSURMIX_HOST=%s\n' "$FQDN" > "$SCRIPT_DIR/.env"
  export ASSUR_DB_USER="$dbu" ASSUR_DB_PASS="$dbp"
  require envsubst
  local spec='${ASSUR_DB_USER} ${ASSUR_DB_PASS}'
  # dossiers runtime (inscriptibles)
  ( cd "$APP_DIR" && mkdir -p $RUNTIME_DIRS )
  envsubst "$spec" < "$SCRIPT_DIR/tpl/pro_constants.php"              > "$APP_DIR/pro/secure/php/constants.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/pro_config.php"                 > "$APP_DIR/pro/secure/php/config.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/pro_bdd_listener.php"           > "$APP_DIR/pro/secure/script/bdd_listener.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/assurfranchise_constants.php"   > "$APP_DIR/assurfranchise/secure/php/constants.php"
  envsubst "$spec" < "$SCRIPT_DIR/tpl/assurance-de-pret_constants.php" > "$APP_DIR/assurance-de-pret/current/secure/php/constants.php"
  ok "Config générée (5 fichiers) + dossiers runtime"
}

patches(){
  # 1) include.php : forcer le require de class.phpmailer (idempotent, best-effort)
  local inc="$APP_DIR/pro/include.php"
  if [ -f "$inc" ] && ! grep -q "class.phpmailer.php'" "$inc"; then
    sed -i "/PHPMailerAutoload\.php');/a require_once (REAL_PATH.'include/PHPMailer-5.2-stable/PHPMailer-5.2-stable/class.phpmailer.php');" "$inc" || true
  fi
  # 2) pro/index.php : sous-domaines produits legacy .fr -> portail (best-effort)
  local idx="$APP_DIR/pro/index.php"
  if [ -f "$idx" ]; then
    sed -i "s#<?= LAST_LEVEL_DOMAIN ?>\.assurski\.fr#${FQDN}/assurance-ski#g;
            s#<?= LAST_LEVEL_DOMAIN ?>\.assursport\.fr#${FQDN}/assurance-sport#g;
            s#<?= LAST_LEVEL_DOMAIN ?>\.assurkids\.fr#${FQDN}/assurance-scolaire#g;
            s#<?= LAST_LEVEL_DOMAIN ?>\.assurfranchise\.fr#${FQDN}/assurance-franchise#g;
            s#<?= LAST_LEVEL_DOMAIN ?>\.assurveto\.fr#${FQDN}/assurance-animaux#g" "$idx" || true
  fi
}

app_bootstrap(){
  info "composer install (si include/Composer/composer.json)…"
  docker exec -e COMPOSER_ALLOW_SUPERUSER=1 "$APP_CT" sh -lc \
    'if [ -f /var/www/html/assurmix/include/Composer/composer.json ]; then cd /var/www/html/assurmix/include/Composer && composer install --no-interaction --no-dev --optimize-autoloader; else echo "pas de composer.json — skip"; fi' \
    || warn "composer a signalé une erreur"
  info "Droits d'écriture…"
  docker exec "$APP_CT" sh -c 'chmod -R a+rwX /var/www/html/assurmix' || true
}

up(){
  require docker; require git; require envsubst
  ensure_secrets_source
  ensure_shared_db
  ensure_traefik_net
  clone_app
  generate_config
  patches
  info "Build + démarrage (docker compose)…"
  dc up -d --build
  app_bootstrap
  echo
  ok "Assurmix dev prêt :"
  echo "     • Via l'edge (Traefik) : ${c_bold}${URL}${c_reset}"
  echo "     • Accès direct (debug) : ${DIRECT_URL}"
  info "Base partagée : portomix_data (assurenv). Portomix garde la racine du domaine."
}

down(){  info "Arrêt Assurmix dev…"; dc down; ok "Arrêté (base partagée conservée)"; }
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
