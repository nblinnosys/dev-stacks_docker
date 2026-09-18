# MGA — dev local

**Ma Garantie Auto** (appli/back-office, PHP 8.2/Apache, code « raw ») + MySQL 8
dédiée `mga_db` (schémas `mga_mb` + `mga_vitrine`).

## Démarrer
```bash
./dev.sh up
```
Puis : **http://localhost:8087/**

## Ce que fait `up`
1. **Clone** `INNOSYSFRANCE/mga` (branche `master`) dans `app/`.
2. Génère les **4 fichiers de conf PHP** (constants / Editor config / cn / rollbar) via `envsubst` (secrets du vault).
3. Copie les dumps `mga_mb.sql` + `mga_vitrine.sql` dans `db/import/` et extrait le **thème Metronic** (`assets.tar.gz`).
4. `docker compose up -d --build` (réseau **`mga`** partagé avec mga_vitrine).
5. Crée `mga_vitrine` + un **`lagon_extranet` vide** (dev) sur `mga_db`, importe les dumps si vides.
6. Applique les **patches PHP 8** + repointe les connexions lagon → `mga_db`.
7. `composer install`.

## Base de données
- DBeaver : `127.0.0.1:3317`, schémas `mga_mb`, `mga_vitrine`, `lagon_extranet` (vide).
- ⚠ En recette MGA lit `lagon_extranet` de Lagon7 en cross-hôte ; en dev on crée un
  schéma **vide** local pour que les connexions PDO ne plantent pas (fonctions lagon
  non peuplées).

## Fichiers requis (machine sans le dépôt recette)
Copie depuis `Innosys_global_rec_prod/sites/mga/files/` :
- `db/import/mga_mb.sql`, `db/import/mga_vitrine.sql`
- `assets.tar.gz` (thème, 115 Mo) → à la racine `dev/mga/`

## Notes
- `ENVIRONNEMENT=DEV` → mails redirigés (MAIL_DEV), Paybox preprod : aucun vrai client contacté.
- mga_vitrine (vitrine publique) réutilise ce `mga_db` → **lancer mga avant** mga_vitrine.
