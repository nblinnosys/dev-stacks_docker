#!/usr/bin/env bash
# =============================================================================
# dev/menu.sh — menu interactif des stacks de dev Innosys.
#   Auto-découvre chaque dev/<site>/dev.sh, affiche name/desc/port (méta lues
#   dans l'en-tête du dev.sh), et déclenche l'action choisie.
#   Aucune release : chaque stack tourne en docker-compose local.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Auto-activation du groupe docker : si l'utilisateur EST membre du groupe docker
# mais que la session ne l'a pas encore pris en compte (docker refuse l'accès), on
# se relance sous « sg docker » -> plus besoin de « newgrp docker » ni de re-login.
if [ -z "${DEV_SG_REEXEC:-}" ] && ! docker info >/dev/null 2>&1; then
  if id -nG 2>/dev/null | tr ' ' '\n' | grep -qx docker && command -v sg >/dev/null 2>&1; then
    warn "Groupe docker pas encore actif dans cette session -> relance via « sg docker »…"
    export DEV_SG_REEXEC=1
    exec sg docker -c "exec bash '$SCRIPT_DIR/menu.sh'"
  fi
fi

banner(){
  printf '\n%s╔══════════════════════════════════════════╗%s\n' "$c_blue" "$c_reset"
  printf   '%s║   INNOSYS · Environnement de DÉV local    ║%s\n' "$c_blue" "$c_reset"
  printf   '%s╚══════════════════════════════════════════╝%s\n\n' "$c_blue" "$c_reset"
}

# Découverte des sites (dossiers contenant un dev.sh)
discover(){
  SITES=()
  local f
  while IFS= read -r f; do SITES+=("$f"); done \
    < <(find "$SCRIPT_DIR" -mindepth 2 -maxdepth 2 -name dev.sh | sort)
  [ "${#SITES[@]}" -gt 0 ] || die "Aucun site trouvé (dev/<site>/dev.sh)."
}

list_sites(){
  local i name desc port
  for i in "${!SITES[@]}"; do
    name="$(meta_get "${SITES[$i]}" name)"; [ -n "$name" ] || name="$(basename "$(dirname "${SITES[$i]}")")"
    desc="$(meta_get "${SITES[$i]}" desc)"
    port="$(meta_get "${SITES[$i]}" port)"
    printf '  %s%2d%s) %s%-14s%s %s%s%s  %s[:%s]%s\n' \
      "$c_bold" "$((i+1))" "$c_reset" \
      "$c_green" "$name" "$c_reset" \
      "$c_dim" "$desc" "$c_reset" \
      "$c_yellow" "$port" "$c_reset"
  done
}

action_menu(){
  local site_sh="$1" name; name="$(meta_get "$site_sh" name)"
  while true; do
    printf '\n%sSite : %s%s\n' "$c_bold" "$name" "$c_reset"
    echo "  1) Déployer / (re)monter"
    echo "  2) Arrêter (garde les données)"
    echo "  3) Logs (Ctrl-C pour quitter)"
    echo "  4) Ouvrir dans le navigateur"
    echo "  5) Réinitialiser (SUPPRIME la BDD)"
    echo "  6) Supprimer l'installation (conteneurs + volume + clone app/)"
    echo "  0) Retour"
    read -rp "Action > " a
    case "$a" in
      1) bash "$site_sh" up ;;
      2) bash "$site_sh" down ;;
      3) bash "$site_sh" logs ;;
      4) bash "$site_sh" url ;;
      5) read -rp "Confirmer la suppression de la BDD ? (o/N) " c
         [ "${c,,}" = "o" ] && bash "$site_sh" reset || info "Annulé." ;;
      6) read -rp "Tout supprimer (conteneurs + volume + clone) ? (o/N) " c
         [ "${c,,}" = "o" ] && bash "$site_sh" destroy || info "Annulé." ;;
      0) return ;;
      *) warn "Choix invalide." ;;
    esac
  done
}

main(){
  require docker
  discover
  while true; do
    banner
    echo "Sites disponibles :"
    list_sites
    printf '\n   %s0%s) Quitter\n' "$c_bold" "$c_reset"
    read -rp $'\nSite > ' s
    [ "$s" = "0" ] && { echo "Bye 👋"; exit 0; }
    if [[ "$s" =~ ^[0-9]+$ ]] && [ "$s" -ge 1 ] && [ "$s" -le "${#SITES[@]}" ]; then
      action_menu "${SITES[$((s-1))]}"
    else
      warn "Choix invalide."
    fi
  done
}

main "$@"
