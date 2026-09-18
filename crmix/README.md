# CRMix — dev local

CRM (PHP 7.3/Apache, Symfony/InnoCore) du pôle assurmix. **Pas de base à lui** :
se connecte à `portomix_data` (dev/base_assur_port_crmix) via `assurenv`.

## Démarrer
```bash
./dev.sh up
```
- Edge : **https://crmix.\<domaine\>/**
- Direct : **http://\<DEV_HOST\>:8093/**

`up` démarre la base partagée si besoin, clone `CRMix`, extrait le **thème Metronic**,
génère `.env` (envsubst), build (PHP 7.3 Buster → archive.debian), puis
`composer install` avec **InnoCore via HTTPS+token** (pas de clé SSH).

## Fichiers requis (machine sans le dépôt recette)
- `metronic_v4.7.5.tar.gz` (thème, 155 Mo) → racine `dev/crmix/` (ou dans le dépôt recette).

## Base
`portomix_data` (MySQL 5.7, base `assurmix`), partagée avec portomix + assurmix.

## Notes
- Image PHP 7.3 **Buster EOL** → dépôts `archive.debian.org` (dans le Dockerfile).
- Thème monté en RO sous `/var/www/theme/metronic_v4.7.5` ; Alias `/metronic`.
- `ENV=development` → mails redirigés vers `MAIL_DEV`.
