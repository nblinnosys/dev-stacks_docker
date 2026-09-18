# Lagon7 — dev local

**Lagon Courtage** (legacy PHP 7.4/Apache) : **2 sites** dans un conteneur, +
MySQL 8 dédiée `lagon_extranet`.

## Démarrer
```bash
./dev.sh up
```
Puis :
- **Site public** : http://lagon.localhost:8089/
- **Extranet** : http://extranet.lagon.localhost:8089/

> `*.localhost` est résolu en 127.0.0.1 par les navigateurs → **pas besoin de /etc/hosts**.

## Ce que fait `up`
1. **Clone** `INNOSYSFRANCE/lagon7` (branche `master`) dans `app/`.
2. Génère les **6 fichiers de conf PHP** de l'extranet (constants / config / inno_cn / mondial_cn / Editor config / rollbar) via `envsubst`.
3. Copie le dump `lagon_extranet.sql` + extrait le **thème Metronic** (`assets.tar.gz`).
4. Patche `twig < 3.5` (compat PHP 7.4), repointe les liens extranet PROD → domaine dev, crée les dossiers d'écriture.
5. `docker compose up -d --build`, importe le dump si vide, `composer install` (extranet/).

## Base de données
- DBeaver : `127.0.0.1:3318`, base `lagon_extranet`.
- MGA/Mondial est **neutralisé** en dev (`$bdd_inassur` repointé sur la base locale).

## Fichiers requis (machine sans le dépôt recette)
Depuis `Innosys_global_rec_prod/sites/lagon/files/` :
- `db/import/lagon_extranet.sql` (141 Mo)
- `assets.tar.gz` (thème, 115 Mo) → racine `dev/lagon/`

## Notes
- Image PHP 7.4 (bullseye EOL) : Dockerfile sur `snapshot.debian.org` + mbstring conditionnel.
- Indépendant de mga en dev (chacun sa base ; en recette MGA lit lagon en cross-hôte).
