# mga-vitrine — dev local

Vitrine publique **Ma Garantie Auto** (PHP 7.4/Apache, routeur bramus, thème Porto).
**PAS de base à elle** : lit le schéma `mga_vitrine` du conteneur `mga_db` (dev/mga).

## ⚠ Prérequis : lancer dev/mga d'abord
La vitrine se branche sur le réseau externe `mga` et lit `mga_db`. Lance **dev/mga**
avant (`./menu.sh` → mga → Déployer), sinon `up` refuse de démarrer.

## Démarrer
```bash
./dev.sh up
```
Puis : **http://localhost:8088/**

## Ce que fait `up`
1. Vérifie que le réseau `mga` + `dev_mga_db` existent (sinon stop).
2. **Clone** `INNOSYSFRANCE/mga-vitrine` (branche `master`) dans `app/`.
3. Génère `include/config.php` via `envsubst` (secrets du vault).
4. Extrait le **thème Porto** (`porto.tar.gz`) dans `app/porto/`.
5. `docker compose up -d --build` (réseau externe `mga`).
6. `composer install` avec **InnoCore via HTTPS+token** (pas de clé SSH).

## Fichiers requis (machine sans le dépôt recette)
- `porto.tar.gz` (thème, 49 Mo) → à la racine `dev/mga_vitrine/` (ou dans le dépôt recette).

## Notes
- `ENVIRONNEMENT=developpement` en dev → affichage des erreurs.
- Le blog/actualités lit aussi `mga_mb` (2ᵉ connexion) → présent grâce à dev/mga.
- Image PHP 7.4 (bullseye EOL) : le Dockerfile bascule sur `snapshot.debian.org`.
