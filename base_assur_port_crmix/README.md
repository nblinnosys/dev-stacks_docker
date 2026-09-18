# base_assur_port_crmix — base partagée du pôle assurmix

Conteneur **`portomix_data`** (MySQL 5.7) sur le réseau externe **`assurenv`**,
partagé par **portomix**, **assurmix** et **crmix** (comme en prod).

## Démarrage
Automatique : lancer un des 3 sites appelle `ensure_shared_db` → démarre ce stack
s'il n'est pas déjà là. Ou à la main :
```bash
./dev.sh up      # down | logs | reset | destroy
```

## « Vérifie avant de construire »
L'import des bases est fait par le script `db/init/00_import.sh` que MySQL n'exécute
**qu'au 1er démarrage** (datadir vide). Si le volume `inno_dev_shared_db_data` existe
déjà → **aucun réimport**. `ensure_shared_db` ne relance pas non plus le conteneur
s'il tourne déjà.

## Dumps requis (machine sans le dépôt / 1er init)
Dépose les **7 dumps** dans `db/import/` **avant le 1er `up`** :
```
assurmix.sql  assurfranchise.sql  assurkids.sql  assurpret.sql
assurski.sql  assursport.sql  assurveto.sql
```
Sans eux, les bases sont créées **vides**. `routes-fix.sql` (routes de souscription)
est repris automatiquement du rôle recette s'il est présent.

## Accès
- Réseau interne : `portomix_data:3306` (pour les sites)
- DBeaver : `127.0.0.1:3307` (ou IP VM), base `assurmix`, user/pass = vault portomix.
