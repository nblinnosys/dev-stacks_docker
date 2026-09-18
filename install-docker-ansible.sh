#!/usr/bin/env bash
# =============================================================================
# install-docker-ansible.sh — installe Docker CE (+ Compose v2) et Ansible.
#   Cible : Debian / Ubuntu (apt).  Idempotent.
#   À lancer en UTILISATEUR NORMAL disposant de sudo (PAS en root) :
#       ./install-docker-ansible.sh
#   Ansible est installé via pipx dans ~/.local/bin (ansible, ansible-playbook,
#   ansible-vault) pour l'utilisateur courant.
# =============================================================================
set -euo pipefail

log(){ printf '\e[36m▸\e[0m %s\n' "$*"; }
ok(){  printf '\e[32m✓\e[0m %s\n' "$*"; }
die(){ printf '\e[31m✗\e[0m %s\n' "$*" >&2; exit 1; }

# --- Garde-fous ---------------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "Ne pas lancer en root : lance-le en utilisateur normal (sudo est utilisé au besoin)."
command -v apt-get >/dev/null 2>&1 || die "Ce script cible Debian/Ubuntu (apt introuvable)."
command -v sudo    >/dev/null 2>&1 || die "sudo requis."

. /etc/os-release
DISTRO_ID="${ID:-}"                 # ubuntu | debian
CODENAME="${VERSION_CODENAME:-}"    # jammy | noble | bookworm ...
[ -n "$CODENAME" ] || CODENAME="$(lsb_release -cs 2>/dev/null || true)"
case "$DISTRO_ID" in
  ubuntu|debian) : ;;
  *) die "Distro non supportée par ce script : '$DISTRO_ID' (attendu ubuntu/debian)." ;;
esac
log "Distribution détectée : $DISTRO_ID $CODENAME"

# =============================================================================
# 1) DOCKER CE + Compose v2 (dépôt officiel Docker)
# =============================================================================
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  ok "Docker + Compose déjà installés ($(docker --version))"
else
  log "Installation des prérequis APT…"
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg

  log "Ajout de la clé GPG Docker…"
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    sudo curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  log "Ajout du dépôt Docker…"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "Installation de Docker Engine + Compose…"
  sudo apt-get update -y
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  sudo systemctl enable --now docker
  ok "Docker installé ($(docker --version))"
fi

# --- Groupe docker (permet d'utiliser docker sans sudo) -----------------------
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
  ok "Utilisateur '$USER' déjà dans le groupe docker"
else
  log "Ajout de '$USER' au groupe docker…"
  sudo usermod -aG docker "$USER"
  NEED_RELOGIN=1
fi

# =============================================================================
# 2) ANSIBLE via pipx (ansible, ansible-playbook, ansible-vault)
# =============================================================================
if command -v ansible >/dev/null 2>&1 || [ -x "$HOME/.local/bin/ansible" ]; then
  ok "Ansible déjà présent ($("${HOME}/.local/bin/ansible" --version 2>/dev/null | head -1 || ansible --version | head -1))"
else
  log "Installation de pipx…"
  # pipx est packagé sur Ubuntu 22.04+/Debian 12 ; fallback via pip si absent.
  if ! sudo apt-get install -y pipx 2>/dev/null; then
    sudo apt-get install -y python3-pip python3-venv
    python3 -m pip install --user pipx
  fi
  # S'assurer que ~/.local/bin est dans le PATH (courant + futurs shells)
  python3 -m pipx ensurepath >/dev/null 2>&1 || "$HOME/.local/bin/pipx" ensurepath >/dev/null 2>&1 || true
  export PATH="$HOME/.local/bin:$PATH"

  log "Installation d'Ansible (pipx)…"
  pipx install --include-deps ansible
  ok "Ansible installé ($("$HOME/.local/bin/ansible" --version | head -1))"
fi

# =============================================================================
# 3) Outils des stacks dev : git (clone) + envsubst (rendu) + newgrp (groupe docker)
# =============================================================================
command -v git      >/dev/null 2>&1 || { log "Installation de git…"; sudo apt-get install -y git; }
command -v envsubst >/dev/null 2>&1 || { log "Installation de gettext-base (envsubst)…"; sudo apt-get install -y gettext-base; }
# `newgrp` (activer le groupe docker sans se reconnecter) : sur Ubuntu 24.04+ il
# est fourni par util-linux-extra (absent des images minimales/cloud).
command -v newgrp    >/dev/null 2>&1 || { log "Installation de util-linux-extra (newgrp)…"; sudo apt-get install -y util-linux-extra || true; }

# =============================================================================
# 4) Droits du dossier dev (souvent copié/transféré depuis un AUTRE utilisateur)
# =============================================================================
DEV_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$DEV_DIR/menu.sh" ] && [ -d "$DEV_DIR/lib" ]; then
  log "Appropriation du dossier dev ($DEV_DIR) à $USER + droits u+rwX…"
  sudo chown -R "$USER":"$USER" "$DEV_DIR"
  chmod -R u+rwX "$DEV_DIR"
  ok "Dossier dev approprié (chown $USER) et droits u+rwX appliqués"
fi

# =============================================================================
# Fin
# =============================================================================
echo
ok "Terminé."
echo "  docker  : $(docker --version 2>/dev/null || echo 'à recharger le shell')"
echo "  compose : $(docker compose version 2>/dev/null | head -1 || echo 'à recharger le shell')"
echo "  ansible : $("$HOME/.local/bin/ansible" --version 2>/dev/null | head -1 || ansible --version 2>/dev/null | head -1 || echo 'ouvre un nouveau shell')"
echo
if [ "${NEED_RELOGIN:-0}" = "1" ]; then
  printf '\e[33m!\e[0m %s\n' "Pour utiliser docker sans sudo : lance 'newgrp docker' PUIS './menu.sh' dans le MÊME terminal"
  printf '  %s\n' "(ou déconnecte/reconnecte ta session). Exemple :  newgrp docker && cd \"$DEV_DIR\" && ./menu.sh"
fi
printf '\e[33m!\e[0m %s\n' "Si 'ansible' n'est pas trouvé, ouvre un NOUVEAU shell (pipx a modifié le PATH)."
