#!/usr/bin/env bash
# =============================================================================
# dev/base_assur_port_crmix/dev.sh — base PARTAGÉE du pôle assurmix (portomix_data, MySQL 5.7).
#   Actions : up (défaut) | down | logs | reset | destroy
#   Démarré automatiquement par portomix/assurmix/crmix (ensure_shared_db), ou à la
#   main. L'import des bases est fait par MySQL au 1er init seulement (idempotent).
#
# Méta (menu.sh) :
#   name: base_assur_port_crmix
#   desc: Base partagée assurmix/portomix/crmix (portomix_data) [INFRA]
#   port: 3307
#   url:  -
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
ROLE_FILES="$REC_ROOT/sites/portomix/files"
MAIN_DB="assurmix"
DB_CT="portomix_data"

cd "$SCRIPT_DIR"

secret(){
  local key="$1" val=""
  if [ -f "$VAULT" ]; then val="$(vault_get "$key" "$VAULT")"
  elif [ -f "$SECRETS_ENV" ]; then val="$( set -a; . "$SECRETS_ENV" >/dev/null 2>&1; printf '%s' "${!key-}" )"; fi
  printf '%s' "$val"
}

gen_env(){
  local dbu dbp dbr
  dbu="$(secret vault_portomix_db_user)"; dbp="$(secret vault_portomix_db_password)"; dbr="$(secret vault_portomix_db_root_password)"
  [ -n "$dbu" ] && [ -n "$dbp" ] && [ -n "$dbr" ] || die "Identifiants DB portomix absents (vault portomix / secrets.env).
   -> Remplis $SECRETS_ENV (vault_portomix_db_user/password/root_password) ou pose le dépôt recette à côté."
  cat > "$SCRIPT_DIR/.env" <<EOF
DB_NAME=$MAIN_DB
DB_USER=$dbu
DB_PASSWORD=$dbp
DB_ROOT_PASSWORD=$dbr
EOF
}

seed_dumps(){
  mkdir -p "$SCRIPT_DIR/db/import"
  # routes-fix.sql (repris du rôle recette) : routes de souscription manquantes.
  [ -f "$SCRIPT_DIR/db/import/routes-fix.sql" ] || \
    { [ -f "$ROLE_FILES/routes-fix.sql" ] && cp "$ROLE_FILES/routes-fix.sql" "$SCRIPT_DIR/db/import/"; } || true
  # Avertissement si les gros dumps manquent (on accepte .sql OU .sql.gz)
  if [ ! -f "$SCRIPT_DIR/db/import/${MAIN_DB}.sql" ] && [ ! -f "$SCRIPT_DIR/db/import/${MAIN_DB}.sql.gz" ]; then
    warn "Dump ${MAIN_DB}.sql absent de db/import/ -> la base sera créée VIDE."
    warn "Dépose les 7 dumps (assurmix.sql, assurfranchise.sql, assurkids.sql, assurpret.sql,"
    warn "assurski.sql, assursport.sql, assurveto.sql) dans dev/base_assur_port_crmix/db/import/ avant le 1er 'up'."
  fi
}

routes_fix(){
  [ -f "$SCRIPT_DIR/db/import/routes-fix.sql" ] || return 0
  info "Injection des routes de souscription (idempotent)…"
  docker exec -i "$DB_CT" sh -c "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $MAIN_DB" < "$SCRIPT_DIR/db/import/routes-fix.sql" 2>/dev/null \
    || warn "routes-fix ignoré (base vide ou tables absentes)"
}

up(){
  require docker
  docker network inspect assurenv >/dev/null 2>&1 || docker network create assurenv >/dev/null
  gen_env
  seed_dumps
  if docker ps --format '{{.Names}}' | grep -qx "$DB_CT"; then
    info "portomix_data déjà démarré."
  else
    info "Démarrage de la base partagée (MySQL 5.7)…"
    dc up -d
  fi
  wait_mysql "$DB_CT" 120     # 1er import volumineux -> patience
  routes_fix
  ok "Base partagée prête : ${c_bold}portomix_data${c_reset} (assurenv) — DBeaver : ${DEV_HOST}:3307"
  info "Bases : $MAIN_DB + assurfranchise/assurkids/assurpret/assurski/assursport/assurveto"
}

down(){  info "Arrêt de la base partagée…"; dc down; ok "Arrêté (données conservées)"; }
logs(){  dc logs -f --tail=100; }
reset(){ warn "Suppression du conteneur + VOLUME (toutes les bases du pôle assurmix)."; dc down -v; ok "Volume supprimé."; }
destroy(){ warn "Suppression complète."; dc down -v --remove-orphans || warn "down a échoué (accès Docker ?)"; rm -f "$SCRIPT_DIR/.env"; ok "Supprimé (secrets.env + dumps conservés)."; }

case "${1:-up}" in
  up|deploy) up ;;
  down|stop) down ;;
  logs)      logs ;;
  reset)     reset ;;
  destroy|purge) destroy ;;
  *) die "Action inconnue : $1 (up|down|logs|reset|destroy)" ;;
esac
