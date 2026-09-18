#!/usr/bin/env bash
# =============================================================================
# dev/traefik/dev.sh — reverse proxy Traefik de la dev (edge -> conteneurs site).
#   Actions : up (défaut) | down | logs | url | reset | destroy
#
# Méta (lue par menu.sh) :
#   name: traefik
#   desc: Reverse proxy (route *.devnico.innosys.fr vers les sites) [INFRA]
#   port: 8080
#   url:  http://localhost:8080/dashboard/
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$DEV_ROOT/lib/common.sh"

cd "$SCRIPT_DIR"
URL="http://${DEV_HOST}:8080/dashboard/"

up(){
  require docker
  ensure_traefik_net
  info "Démarrage de Traefik (routage *.$DEV_DOMAIN)…"
  dc up -d
  echo
  ok "Traefik prêt. Dashboard : ${c_bold}${URL}${c_reset}"
  info "Backend HAProxy (pfSense) -> cette VM sur le port 80."
  info "Chaque site déployé s'enregistre via ses labels (Host <sous-domaine>.$DEV_DOMAIN)."
}
down(){  info "Arrêt Traefik…"; dc down; ok "Arrêté"; }
logs(){  dc logs -f --tail=100; }
url(){   echo "$URL"; open_url "$URL"; }
reset(){ dc down; ok "Fait."; }
destroy(){ dc down --remove-orphans || warn "down a échoué (accès Docker ?)"; ok "Traefik arrêté/supprimé (réseau dev_traefik conservé pour les sites)."; }

case "${1:-up}" in
  up|deploy) up ;;
  down|stop) down ;;
  logs)      logs ;;
  url|open)  url ;;
  reset)     reset ;;
  destroy|purge) destroy ;;
  *) die "Action inconnue : $1 (up|down|logs|url|reset|destroy)" ;;
esac
