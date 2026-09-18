# Portomix — dev local

Portail public du pôle **assurmix** (PHP 7.4/Apache, code Portomix2025).
**Pas de base à lui** : se connecte à `portomix_data` (dev/base_assur_port_crmix) via le réseau
`assurenv`.

## Démarrer
```bash
./dev.sh up
```
- Edge : **https://assurmix.\<domaine\>/**
- Direct : **http://\<DEV_HOST\>:8091/**

`up` démarre d'abord la **base partagée** si elle n'est pas là (`ensure_shared_db`),
sans la reconstruire si elle existe déjà, puis clone Portomix2025, génère
`include/config.php` (envsubst) et fait `composer install`.

## Base
`portomix_data` (MySQL 5.7, réseau `assurenv`), base `assurmix`. DBeaver :
`127.0.0.1:3307`. Voir `dev/base_assur_port_crmix/` pour les dumps.

## Note
`assurmix` (back-office `/pro`) et `crmix` partagent cette même base — ils se
brancheront aussi sur `assurenv`.
