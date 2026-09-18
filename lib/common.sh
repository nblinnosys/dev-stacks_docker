#!/usr/bin/env bash
# =============================================================================
# dev/lib/common.sh — helpers partagés par les stacks de dev Innosys.
#   Sourcé par menu.sh et par chaque dev/<site>/dev.sh.
# =============================================================================

# Hôte d'accès DIRECT aux stacks (ports publiés). localhost par défaut ; mettre
# l'IP du serveur pour un accès direct depuis un autre poste : export DEV_HOST=10.100.0.x
: "${DEV_HOST:=localhost}"

# Domaine de base pour le routage par Traefik (edge pfSense -> Traefik -> conteneurs).
# Chaque site est publié en https://<sous-domaine>.$DEV_DOMAIN via le wildcard.
: "${DEV_DOMAIN:=devmarek.innosys.fr}"

# Réseau Docker partagé entre Traefik et les sites.
: "${DEV_TRAEFIK_NET:=dev_traefik}"

# Garantit l'existence du réseau Traefik (idempotent) : les sites peuvent démarrer
# même si le stack Traefik n'est pas encore lancé.
ensure_traefik_net(){
  docker network inspect "$DEV_TRAEFIK_NET" >/dev/null 2>&1 || docker network create "$DEV_TRAEFIK_NET" >/dev/null
}

# Garantit la base PARTAGÉE du pôle assurmix (conteneur portomix_data, réseau
# assurenv). Appelé par portomix/assurmix/crmix : vérifie si la base tourne déjà
# AVANT de (re)lancer sa construction. L'import n'a lieu qu'au 1er init (datadir
# vide) -> jamais d'écrasement si la base existe. Nécessite $DEV_ROOT défini.
ensure_shared_db(){
  docker network inspect assurenv >/dev/null 2>&1 || docker network create assurenv >/dev/null
  if docker ps --format '{{.Names}}' | grep -qx portomix_data; then
    info "Base partagée portomix_data déjà démarrée -> réutilisée (pas de reconstruction)."
    return 0
  fi
  info "Base partagée absente -> démarrage de dev/base_assur_port_crmix…"
  bash "$DEV_ROOT/base_assur_port_crmix/dev.sh" up
}

# Couleurs (désactivées si pas un terminal)
if [ -t 1 ]; then
  c_reset=$'\e[0m'; c_bold=$'\e[1m'; c_dim=$'\e[2m'
  c_green=$'\e[32m'; c_yellow=$'\e[33m'; c_red=$'\e[31m'; c_blue=$'\e[36m'
else
  c_reset=''; c_bold=''; c_dim=''; c_green=''; c_yellow=''; c_red=''; c_blue=''
fi

info(){ printf '%s▸%s %s\n' "$c_blue"   "$c_reset" "$*"; }
ok(){   printf '%s✓%s %s\n' "$c_green"  "$c_reset" "$*"; }
warn(){ printf '%s!%s %s\n' "$c_yellow" "$c_reset" "$*"; }
die(){  printf '%s✗%s %s\n' "$c_red"    "$c_reset" "$*" >&2; exit 1; }

require(){ command -v "$1" >/dev/null 2>&1 || die "Commande requise absente : $1"; }

# Wrapper docker compose (v2 « docker compose », fallback « docker-compose »)
dc(){
  if docker compose version >/dev/null 2>&1; then docker compose "$@"
  else docker-compose "$@"; fi
}

# vault_get <clef> <fichier-vault> -> valeur (gère vault chiffré OU en clair)
vault_get(){
  local key="$1" file="$2"
  [ -f "$file" ] || die "Vault introuvable : $file"
  if head -1 "$file" | grep -q '\$ANSIBLE_VAULT'; then
    require ansible-vault
    ansible-vault view "$file" 2>/dev/null \
      | sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" | head -1 | sed 's/^"//; s/"$//'
  else
    sed -n "s/^[[:space:]]*${key}:[[:space:]]*//p" "$file" | head -1 | sed 's/^"//; s/"$//'
  fi
}

# Attend qu'un conteneur MySQL réponde vraiment (healthcheck trop précoce au 1er init)
wait_mysql(){
  local container="$1" tries="${2:-60}" i
  for i in $(seq 1 "$tries"); do
    if docker exec "$container" sh -c 'mysql -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1'; then
      return 0
    fi
    sleep 3
  done
  die "MySQL ($container) non prête après $((tries*3))s"
}

# Ouvre une URL dans le navigateur (best-effort, multi-OS)
open_url(){
  local url="$1"
  if   command -v xdg-open >/dev/null 2>&1; then xdg-open "$url" >/dev/null 2>&1 &
  elif command -v open      >/dev/null 2>&1; then open "$url" >/dev/null 2>&1 &
  elif command -v powershell.exe >/dev/null 2>&1; then powershell.exe /c start "$url" >/dev/null 2>&1 &
  else info "Ouvre manuellement : $url"; fi
}

# Lit un champ de méta dans l'en-tête d'un dev.sh :  # <champ>: valeur
meta_get(){ sed -n "s/^#[[:space:]]*$2:[[:space:]]*//p" "$1" | head -1; }

# Supprime TOUTE l'installation d'un stack : conteneurs + volumes + réseau + clone
# app/ + .env généré. Conserve secrets.env et db/import (fournis par l'utilisateur).
# Utilise SCRIPT_DIR (défini par le dev.sh appelant) et dc().
stack_destroy(){
  warn "Suppression COMPLÈTE : conteneurs + volume BDD + clone app/ + .env générés."
  # ⚠ NE PAS masquer l'erreur : un down qui échoue (droits Docker, etc.) doit se voir,
  # sinon on croit avoir supprimé alors que les conteneurs tournent encore.
  if dc down -v --remove-orphans; then
    :
  else
    warn "« docker compose down » a ÉCHOUÉ -> les conteneurs sont peut-être encore là."
    warn "Vérifie l'accès Docker (groupe docker + re-login / newgrp docker) puis relance."
  fi
  rm -rf "$SCRIPT_DIR/app" "$SCRIPT_DIR/.env" 2>/dev/null || true
  if [ -d "$SCRIPT_DIR/app" ]; then
    warn "app/ non supprimé (droits) -> tentative en sudo…"
    sudo rm -rf "$SCRIPT_DIR/app" || true
  fi
  ok "Nettoyage terminé (secrets.env et db/import conservés)."
}
