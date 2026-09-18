# ODC — dev local

**Œuvre des Campagnes** (Laravel + Backpack v6, PHP 8.1/Apache) + MySQL 8, en local,
sans releases.

## Démarrer
```bash
./dev.sh up
```
Puis : **https://localhost:8443/login** (l'admin Backpack est à la **racine**,
`route_prefix` vide — pas de `/admin`). Cert **auto-signé** → accepter l'avertissement
du navigateur une fois. L'appli force le https pour ses assets (comme en prod derrière
l'edge TLS) ; c'est pourquoi la dev sert aussi en TLS.

## Ce que fait `up`
1. **Clone** `INNOSYSFRANCE/odc` (branche `main`) dans `app/` s'il manque (token lu dans le vault recette).
2. Génère `.env` (compose), `app/.env` (Laravel dev) et `app/auth.json` (Backpack + github-oauth).
3. Copie le dump recette `oeuvre_des_campagnes.sql` dans `db/import/`.
4. `docker compose up -d --build`.
5. **Import du dump** si la base est vide.
6. `composer install`, `chown www-data`, `artisan migrate / storage:link / optimize:clear`.

## Accès
- Web : https://localhost:8443/  (login : `/login`) — http://localhost:8086 redirige vers https
- BDD (DBeaver / MySQL Workbench) : `127.0.0.1:3316`, base `oeuvre_des_campagnes`
  (identifiants dans le vault recette `sites/odc/vault.yml`).

## Édition du code
`app/` est un vrai clone git bind-monté : édite dedans, Apache sert directement.
`app/`, `.env`, `db/import/*.sql` sont **gitignorés**.

# Configuration

- Changer la variable d'environnement mail_dev pour recevoir les mails envoyés par ODC

## Notes
- Backpack **Pro** (payant) : `composer install` a besoin des identifiants
  `backpackforlaravel.com` (présents dans le vault). Sinon l'install échoue sur `backpack/pro`.
- Mail = `log` (aucun envoi réel ; voir `storage/logs/laravel.log`).
