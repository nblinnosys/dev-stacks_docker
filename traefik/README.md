# Traefik — reverse proxy de la dev

Route le flux venant de **pfSense/HAProxy** (qui termine le TLS `*.devnico.innosys.fr`)
vers les **conteneurs site**, par `Host(<sous-domaine>.devnico.innosys.fr)`.

```
navigateur ──https──▶ pfSense (cert *.devnico.innosys.fr, HAProxy)
   ──http (X-Forwarded-Proto: https)──▶ VM VPN:80 ──▶ Traefik (ce conteneur)
   ──Host(`odc.devnico.innosys.fr`)──▶ conteneur odc:80
```

## Démarrer
```bash
cd dev/traefik && ./dev.sh up
# dashboard : http://<host>:8080/dashboard/
```

Traefik écoute sur **:80** (cible du backend HAProxy) et découvre les sites par leurs
**labels Docker** (`traefik.enable=true`) sur le réseau partagé **`dev_traefik`**.

## Côté pfSense (à faire une fois)
1. **DNS** : `*.devnico.innosys.fr` → IP publique pfSense (déjà fait).
2. **Certificat** : wildcard `*.devnico.innosys.fr` (déjà fait).
3. **HAProxy** :
   - Frontend : SNI/Host `*.devnico.innosys.fr` (ou `(.*)\.devnico\.innosys\.fr`) sur le frontend 443, cert wildcard.
   - **Backend** : serveur = **IP VPN de la VM dev : 80** (là où écoute Traefik), mode http.
   - Cocher l'ajout de `X-Forwarded-Proto https` (ou laisser Traefik le forcer : déjà fait via middlewares).

## Sous-domaines routés
| Site | Host |
|---|---|
| odc | `odc.devnico.innosys.fr` |
| mga | `mga.devnico.innosys.fr` |
| mga_vitrine | `mga-vitrine.devnico.innosys.fr` |
| lagon (public) | `lagon.devnico.innosys.fr` |
| lagon (extranet) | `lagon-extranet.devnico.innosys.fr` |

> Domaine de base configurable : `export DEV_DOMAIN=autre.domaine` avant `./menu.sh`.
