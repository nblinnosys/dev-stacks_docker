# Environnement de développement local Innosys

Stacks Docker **locales** pour développer les sites, **sans ansistrano ni releases** :
chaque site tourne en `docker-compose` avec son code cloné et **bind-monté** (édition
live), et sa base importée depuis le dump de recette.

## Prérequis
- Docker + Docker Compose v2 (`docker compose`)
- `git`
- Bash (Linux, WSL, ou Git Bash)
- Le dépôt `Innosys_global_rec_prod/` présent **à côté** de `dev/` (source des secrets
  et des dumps : `sites/<site>/vault.yml` + `files/database/*.sql`)

## Utilisation

```bash
cd dev
./menu.sh
```

### Accès via l'edge Traefik (recommandé : *.devnico.innosys.fr)
Modèle identique à la recette : pfSense (TLS + HAProxy) → VM → **Traefik conteneur**
→ conteneurs site, routés par sous-domaine.
```bash
cd dev/traefik && ./dev.sh up      # démarre le proxy (écoute :80, dashboard :8080)
cd .. && ./menu.sh                 # déployer chaque site : il s'enregistre dans Traefik
```
Chaque site est alors servi en `https://<sous-domaine>.devnico.innosys.fr` (cf.
`dev/traefik/README.md` pour la conf pfSense/HAProxy). Domaine réglable :
`export DEV_DOMAIN=autre.domaine`.

### Accès direct par IP/port (debug, sans Traefik)
Les ports restent publiés. Pour des URLs correctes en accès direct depuis un autre
poste, `export DEV_HOST=<ip-serveur>` avant `./menu.sh`.

Le menu liste les sites disponibles (tout dossier contenant un `dev.sh`), puis propose :
**Déployer / Arrêter / Logs / Ouvrir / Réinitialiser**.

Ou en direct, sans menu :

```bash
cd dev/odc
./dev.sh up      # clone + build + up + import dump + composer + migrate
./dev.sh down    # arrête (garde les données)
./dev.sh logs
./dev.sh url     # affiche/ouvre l'URL
./dev.sh reset   # supprime conteneurs + volume BDD (repart du dump au prochain up)
```

## Principes de la structure

| Élément | Rôle |
|---|---|
| `menu.sh` | Menu interactif, auto-découvre `dev/*/dev.sh` (méta dans l'en-tête). |
| `lib/common.sh` | Helpers partagés (couleurs, `docker compose`, lecture vault, attente MySQL). |
| `<site>/dev.sh` | Cycle de vie de la stack (`up/down/logs/url/reset`). |
| `<site>/docker-compose.yml` | Services **avec ports publiés sur localhost** (pas de Traefik). |
| `<site>/app/` | Clone git du code applicatif (bind-monté). *Gitignoré.* |
| `<site>/db/import/` | Dump(s) SQL copiés depuis la recette. *Gitignoré.* |

**Secrets** : lus directement dans le vault recette (`sites/<site>/vault.yml`) — source
unique, rien à ressaisir. Fonctionne que le vault soit en clair ou chiffré
(`ansible-vault view` automatique si chiffré).

## Sites

| Site | URL locale | Port BDD | Base |
|---|---|---|---|
| **odc** | https://localhost:8443/login (TLS auto-signé) | 3316 | `oeuvre_des_campagnes` |
| **mga** | http://localhost:8087/ | 3317 | `mga_mb` + `mga_vitrine` (+`lagon_extranet` vide) |
| **mga_vitrine** | http://localhost:8088/ (lance **mga** avant) | — (lit `mga_db`) | `mga_vitrine` |
| **lagon** | public http://HOST:8089/ · extranet http://HOST:8090/ | 3318 | `lagon_extranet` |

> `HOST` = `localhost` par défaut, ou l'IP du serveur via `export DEV_HOST=<ip>`.
> **mga_vitrine dépend de mga** : lance dev/mga avant (réseau `mga` + `mga_db`).
> **lagon** : 2 sites routés **par port** (8089 public / 8090 extranet) → marche avec l'IP.

> Ajouter un site = créer `dev/<site>/` avec `dev.sh` (en-tête `name/desc/port/url`),
> `docker-compose.yml`, `Dockerfile`, sa conf. Le menu le détecte automatiquement.
