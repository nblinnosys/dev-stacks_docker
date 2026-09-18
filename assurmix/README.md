# Assurmix — dev local

Back-office **« pro »** du pôle assurmix (PHP 5.6/Apache, code legacy).
**Pas de base à lui** : se connecte à `portomix_data` (dev/base_assur_port_crmix) via `assurenv`.

## Démarrer
```bash
./dev.sh up
```
- Edge : **https://assurmix.\<domaine\>/pro/**
- Direct : **http://\<DEV_HOST\>:8092/pro/**

`up` démarre la base partagée si besoin (`ensure_shared_db`), clone `assurmix`,
génère les 5 fichiers de conf (envsubst), crée les dossiers runtime, applique les
patches legacy, puis `composer install` si présent.

## Routage
Même domaine que portomix. Traefik route **uniquement `/pro`** vers assurmix
(priorité 100) ; la **racine** reste sur **portomix**. DocumentRoot = `pro/`
(+ Alias `/pro` pour les URLs absolues du code).

## Base
`portomix_data` (MySQL 5.7, base `assurmix`), partagée avec portomix et crmix.
Rien à importer : la base est déjà là (cf. `dev/base_assur_port_crmix/`).
