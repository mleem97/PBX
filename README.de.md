# FreePBX 17 Docker Container

🚀 **Produktionsreifer FreePBX-17 + Asterisk-Container** für VoIP-Deployments — Debian- und Alpine-Varianten, Asterisk 18–22.

👉 **English version:** [README.md](README.md)

![Docker Pulls](https://img.shields.io/docker/pulls/mleem97/lnxr-freepbx)
![Docker Image Size](https://img.shields.io/docker/image-size/mleem97/lnxr-freepbx/17)
![CI](https://github.com/mleem97/PBX/actions/workflows/ci.yml/badge.svg)
![GitHub](https://img.shields.io/github/license/mleem97/PBX)

## Inhalt

- [Features](#-features)
- [Architektur](#-architektur)
- [Image-Tags](#-image-tags)
- [Voraussetzungen](#-voraussetzungen)
- [Schnellstart](#-schnellstart)
- [Setup (Compose & .env)](#-setup-compose--env)
- [Umgebungsvariablen](#-umgebungsvariablen)
- [Ports](#-ports)
- [Volumes & Backup](#-volumes--backup)
- [Reverse Proxy (nginx, Traefik, Caddy)](#-reverse-proxy-nginx-traefik-caddy)
- [TLS / HTTPS](#-tls--https)
- [Screenshots](#-screenshots)
- [Health Checks & Monitoring](#-health-checks--monitoring)
- [Build & Entwicklung](#-build--entwicklung)
- [CI & Automatisierung](#-ci--automatisierung)
- [Fehlerbehebung](#-fehlerbehebung)
- [Sicherheitshinweise](#-sicherheitshinweise)
- [Projektstruktur](#-projektstruktur)
- [Mitwirken & Support](#-mitwirken--support)

## ✨ Features

- ✅ **FreePBX 17** mit Web-Oberfläche
- ✅ **Asterisk 18–22** (siehe [Tags](#-image-tags)), aus den Quellen gebaut mit MP3 (`format_mp3`) und Crypto (`res_crypto`)
- ✅ **Multi-Service-Orchestrierung** via Supervisor (MariaDB → Asterisk → PHP-FPM → Nginx)
- ✅ **Debian-12- und Alpine-3.20-Varianten** (Alpine-Images ca. 20 % kleiner)
- ✅ **Persistente Named Volumes** für Konfiguration, Datenbank, Webdateien und Logs
- ✅ **Health Checks**, strukturiertes Logging, Build-Automatisierung (`build.sh`, `Makefile`)
- ✅ **Reverse-Proxy-ready** (Beispiele für nginx, Traefik und Caddy unten)

## 🏗️ Architektur

Ein Container betreibt vier supervisorte Dienste in strikter Startreihenfolge:

| Priorität | Dienst | Beschreibung |
|-----------|--------|--------------|
| 10 | **MariaDB 10.11** | Datenbank-Backend (`mysqld`) |
| 20 | **Asterisk** | PBX-Kern (`asterisk -f`) |
| 30 | **PHP-FPM 8.2** | FreePBX-Web-Backend |
| 40 | **Nginx** | Webserver-Frontend (Port 80) |

Beim **ersten Start** initialisiert der Entrypoint (`entrypoint.sh`) MariaDB, startet Asterisk temporär, führt den FreePBX-Installer aus (`./install -n`) und übergibt dann an Supervisord. Der Erststart dauert **2–5 Minuten** — mit `docker logs <container>` verfolgen.

> **Hinweis:** `supervisorctl status` funktioniert direkt im Container (eine `unix_http_server`-Sektion ist enthalten).

## 🏷️ Image-Tags

Images: `mleem97/lnxr-freepbx:<tag>` ([Docker Hub](https://hub.docker.com/repository/docker/mleem97/lnxr-freepbx)).

| Tag | Basis | Asterisk | Anmerkung |
|-----|-------|----------|-----------|
| `17` | Debian 12 | 21 | Produktions-Image (FreePBX 17) |
| `dev` | Debian 12 | 21 | Aus `main` gebaut, für Entwicklung/Tests |
| `17-alpine` | Alpine 3.20 | 21 | Kleinere Produktions-Alternative |
| `18`, `18-alpine` | Debian 12 / Alpine 3.20 | **18.26.4** (gepinnt, EOL-Branch) | |
| `19`, `19-alpine` | Debian 12 / Alpine 3.20 | **19.8.1** (gepinnt, EOL-Branch) | |
| `20`, `20-alpine` | Debian 12 / Alpine 3.20 | 20 (aktueller Branch) | |
| `21`, `21-alpine` | Debian 12 / Alpine 3.20 | 21 (aktueller Branch) | Gleiches Asterisk wie `17`/`17-alpine` |
| `22`, `22-alpine` | Debian 12 / Alpine 3.20 | 22 (aktueller Branch) | Neuestes |

> Es gibt **kein `latest`-Tag**. Die Tags `18`/`19` sind auf die letzten Releases ihrer (abgekündigten) Branches gepinnt, weil es dort keine `*-current`-Symlinks mehr gibt. FreePBX 17 unterstützt Asterisk 18–22.

```bash
docker pull mleem97/lnxr-freepbx:17          # Debian-Produktion
docker pull mleem97/lnxr-freepbx:17-alpine   # Alpine-Produktion
docker pull mleem97/lnxr-freepbx:22          # Neuestes Asterisk, Debian
```

## 📋 Voraussetzungen

- Docker Engine 24+ mit Compose v2 (`docker compose`)
- **mind. 2 GB RAM**, 4 GB+ für Produktion empfohlen
- Architektur **amd64**
- Freigegebene Ports (siehe [Ports](#-ports)); RTP-Bereich `10000–20000/udp` muss für Audio erreichbar sein

## 🚀 Schnellstart

### Von Docker Hub (empfohlen)

```bash
docker run -d --name freepbx \
  --restart unless-stopped \
  -p 8080:80 -p 8443:443 \
  -p 5060:5060/udp -p 5061:5061/udp \
  -p 10000-20000:10000-20000/udp \
  -v freepbx_db:/var/lib/mysql \
  -v freepbx_config:/etc/asterisk \
  -v freepbx_www:/var/www/html \
  -e TZ=Europe/Berlin \
  mleem97/lnxr-freepbx:17
```

Nach einigen Minuten (Erstinstallation!) Web-Oberfläche unter **http://localhost:8080** öffnen.

### Aus den Quellen (Entwicklung)

```bash
git clone https://github.com/mleem97/PBX.git
cd PBX

# Debian-Dev-Container
make dev-deploy        # oder: ./build.sh dev && docker compose up -d

# Alpine-Variante
docker compose -f docker-compose.alpine.yml up -d --build
```

## ⚙️ Setup (Compose & .env)

Drei Compose-Dateien liegen bei:

| Datei | Zweck |
|-------|-------|
| `docker-compose.yml` | Entwicklung (baut `dockerfile`, Tag `dev`) |
| `docker-compose.alpine.yml` | Alpine-Variante (baut `dockerfile.alpine`, Tag `17-alpine`) |
| `docker-compose.prod.yml` | Produktion (zieht `mleem97/lnxr-freepbx:<tag>`, konfigurierbar per `.env`) |

```bash
# 1. Env-Datei anlegen
cp .env.example .env.prod

# 2. .env.prod anpassen (Ports, Zeitzone, Image-Tag, SSL-Pfad)
# 3. Produktion starten
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Oder per Deploy-Helfer (pull -> neu erstellen -> auf healthy warten)
./deploy.sh
```

Alle Makefile-Ziele: `make help`. Die wichtigsten: `make build-dev|build-prod|build-alpine|build-versions`, `make push-*`, `make up-dev|up-prod|up-alpine`, `make down-*`, `make logs|logs-prod`, `make shell-dev|shell-prod`, `make asterisk-cli`, `make status`, `make clean`.

## 🔧 Umgebungsvariablen

### Produktions-Compose (`docker-compose.prod.yml` ← `.env` / `.env.prod`)

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `IMAGE_REGISTRY` | `mleem97` | Registry/Namespace des Images |
| `IMAGE_TAG` | `17` | Zu startender Image-Tag (z. B. `17`, `22`, `17-alpine`) |
| `HTTP_PORT` | `8080` | Host-Port → Container-Port 80 (Web-UI) |
| `HTTPS_PORT` | `8443` | Host-Port → Container-Port 443 (reserviert, siehe [TLS](#-tls--https)) |
| `SIP_PORT` | `5060` | Host-Port → SIP-Signalisierung UDP |
| `SIPS_PORT` | `5061` | Host-Port → sicheres SIP UDP |
| `RTP_START` / `RTP_END` | `10000` / `20000` | Host-RTP-Bereich → Container `10000–20000/udp` |
| `TIMEZONE` | `Europe/Berlin` | Wird auf Container-`TZ` gemappt |
| `MYSQL_ROOT_PASSWORD` | *(leer)* | **Reserviert** — wird aktuell nicht an MariaDB angewendet |
| `SSL_CERT_PATH` | `./ssl` | Host-Verzeichnis, read-only nach `/etc/ssl/certs/freepbx` gemountet |
| `COMPOSE_FILE` / `ENV_FILE` | (nur deploy.sh) | Datei-Auswahl für `./deploy.sh` |

### Container-Laufzeit

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `TZ` | `Europe/Berlin` | Zeitzone des Containers |

### Build (`build.sh`)

| Variable | Standard | Beschreibung |
|----------|----------|--------------|
| `DOCKER_HUB_USER` | `mleem97` | Namespace beim Pushen |
| `DOCKER_REGISTRY` | `docker.io` | Registry beim Pushen |

`./build.sh [dev|prod|alpine|versions|all] [--push]` — `versions` baut die Tags `18–22` (+ je `-alpine`); EOL-Branches 18/19 nutzen gepinnte Release-Tarballs (siehe `tarball_for_version` in `build.sh`).

## 🔌 Ports

| Container-Port | Protokoll | Zweck | Typisches Host-Mapping |
|----------------|-----------|-------|------------------------|
| `80` | TCP | FreePBX-Web-UI (HTTP) | `8080` |
| `443` | TCP | Reserviert (kein TLS-Block by default, siehe [TLS](#-tls--https)) | `8443` |
| `5060` | UDP | SIP-Signalisierung | `5060` |
| `5061` | UDP | Sicheres SIP (TLS) | `5061` |
| `10000–20000` | UDP | RTP-Media (Audio) | `10000–20000` |

> SIP und RTP **müssen** direkt auf dem Host veröffentlicht werden (UDP-Portweiterleitung). Nur die HTTP-Web-UI gehört hinter einen Reverse Proxy — L7-Proxys können den dynamischen RTP-Bereich nicht abbilden (siehe unten).

Firewall-Beispiel (UFW):

```bash
sudo ufw allow 8080/tcp
sudo ufw allow 5060,5061/udp
sudo ufw allow 10000:20000/udp
```

## 💾 Volumes & Backup

Named Volumes je Compose-Datei (Prod-Volumes heißen `*_prod`, z. B. `freepbx_db_prod`):

| Mountpunkt | Inhalt | Kritisch? |
|------------|--------|-----------|
| `/var/lib/mysql` | MariaDB-Datenbanken | ⭐ am kritischsten |
| `/etc/asterisk` | Asterisk-Konfiguration | ja |
| `/var/lib/asterisk` | Asterisk-Laufzeitdaten | ja |
| `/var/www/html` | FreePBX-Webdateien | ja |
| `/var/log` (dev: `/var/log/asterisk`) | Logs | nein |
| `/var/spool/asterisk` | Call-Verarbeitung | nein |

Backup-Beispiel:

```bash
docker run --rm \
  -v freepbx_db_prod:/source/db \
  -v freepbx_etc_asterisk_prod:/source/config \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/freepbx-backup-$(date +%Y%m%d).tar.gz -C /source .
```

## 🔀 Reverse Proxy (nginx, Traefik, Caddy)

**Faustregel:** Nur die Web-UI (Container-Port 80) hinter den Proxy. SIP (`5060–5061/udp`) und RTP (`10000–20000/udp`) direkt auf dem Docker-Host lassen — der Proxy steht idealerweise auf demselben Host oder einer Maschine mit 1:1-UDP-Weiterleitung.

FreePBX läuft hinter einem TLS-terminierenden Proxy intern mit plain HTTP; bei Login-Loops **„Redirect to HTTPS“ ausschalten** in FreePBX unter *Admin → System Admin → HTTPS Setup* (bzw. *Advanced Settings → HTTP(S)*), da TLS der Proxy macht.

### Variante A: nginx (eigener Host oder Container)

```nginx
# /etc/nginx/sites-available/freepbx
upstream freepbx { server 127.0.0.1:8080; }

server {
    listen 80;
    server_name pbx.example.com;
    return 301 https://$host$request_uri;  # ACME-Challenge ggf. ausnehmen
}

server {
    listen 443 ssl;
    server_name pbx.example.com;

    ssl_certificate     /etc/letsencrypt/live/pbx.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pbx.example.com/privkey.pem;

    client_max_body_size 20M;

    location / {
        proxy_pass http://freepbx;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # UCP / WebSocket-Support
    location /ws {
        proxy_pass http://freepbx;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Variante B: Traefik (Labels am FreePBX-Service)

Traefik terminiert TLS für die Web-UI; SIP/RTP bleiben auf Host-Ports.

```yaml
services:
  freepbx:
    image: mleem97/lnxr-freepbx:17
    ports:
      - "5060:5060/udp"
      - "5061:5061/udp"
      - "10000-20000:10000-20000/udp"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.freepbx.rule=Host(`pbx.example.com`)"
      - "traefik.http.routers.freepbx.entrypoints=websecure"
      - "traefik.http.routers.freepbx.tls.certresolver=letsencrypt"
      - "traefik.http.services.freepbx.loadbalancer.server.port=80"
    environment:
      - TZ=Europe/Berlin
    volumes:
      - freepbx_db:/var/lib/mysql
      - freepbx_config:/etc/asterisk
      - freepbx_www:/var/www/html
```

> SIP/RTP **nicht** über Traefik-TCP/UDP-Router leiten — wie oben auf dem Host veröffentlichen.

### Variante C: Caddy (am einfachsten, HTTPS automatisch)

```
pbx.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

```bash
# Container veröffentlicht nur Nötiges + VoIP-UDP direkt:
docker run -d --name freepbx --restart unless-stopped \
  -p 127.0.0.1:8080:80 \
  -p 5060:5060/udp -p 5061:5061/udp -p 10000-20000:10000-20000/udp \
  -v freepbx_db:/var/lib/mysql -v freepbx_config:/etc/asterisk -v freepbx_www:/var/www/html \
  mleem97/lnxr-freepbx:17
```

## 🔒 TLS / HTTPS

Das mitgelieferte Nginx serviert **plain HTTP auf Port 80**. Port 443 ist exposed, hat aber **standardmäßig keinen TLS-Serverblock** — TLS am Reverse Proxy terminieren (empfohlen, siehe oben).

Wer TLS unbedingt im Container will: Zertifikate nach `/etc/ssl/certs/freepbx:ro` mounten (siehe `SSL_CERT_PATH`) und einen `listen 443 ssl;`-Serverblock (mit `ssl_certificate` / `ssl_certificate_key` auf die gemounteten Dateien) in einer eigenen Nginx-Config ergänzen.

## 📸 Screenshots

Frischer Erststart — FreePBX-Setup-Wizard (`/admin/config.php`):

![FreePBX-Erstinstallation](docs/screenshots/01-login.png)

## 🩺 Health Checks & Monitoring

Das Produktions-Compose enthält einen Healthcheck (`curl http://localhost/admin/config.php`, 30-s-Intervall, 120 s Startphase).

```bash
# Service-Überblick (im Container)
docker exec -it lnxr-freepbx-prod supervisorctl status
# Einzelnen Dienst neustarten
docker exec -it lnxr-freepbx-prod supervisorctl restart asterisk
# Asterisk-CLI
docker exec -it lnxr-freepbx-prod asterisk -r
asterisk -rx "core show version"
asterisk -rx "pjsip show endpoints"
# Logs
docker logs lnxr-freepbx-prod
docker exec -it lnxr-freepbx-prod tail -f /var/log/asterisk-supervisor.log
```

## 🛠️ Build & Entwicklung

```bash
./build.sh dev              # Debian-Dev-Image (lnxr-freepbx:dev)
./build.sh prod             # dev -> 17 umtaggen
./build.sh alpine           # Alpine-Image (lnxr-freepbx:17-alpine)
./build.sh versions         # Tags 18-22 + -alpine-Varianten
./build.sh all --push       # dev + 17 + 17-alpine bauen und nach Docker Hub pushen
```

Dockerfiles:

| Datei | Basis | Wofür |
|-------|-------|-------|
| `dockerfile` | Debian 12, single-stage | Legacy/Referenz |
| `dockerfile.optimized` | Debian 12, multi-stage | `dev`, `17`, `18`–`22` (Build-Args `ASTERISK_VERSION` / `ASTERISK_TARBALL_URL`) |
| `dockerfile.alpine` | Alpine 3.20, multi-stage | `17-alpine`, `18-alpine`–`22-alpine` (musl-fähiger Asterisk-Build, gleiche Build-Args) |

> Der Alpine-Build kompiliert Asterisk auf musl libc inkl. kleiner Kompatibilitäts-Patches (BSD-Makros `__P`/`__BEGIN_DECLS`/`ALLPERMS`, rekursive statische Mutexes, `-rdynamic`-Linking). Details als Kommentare in `dockerfile.alpine`.

## 🤖 CI & Automatisierung

`.github/workflows/ci.yml` läuft bei jedem Push auf `main`, bei Pull Requests, wöchentlich (montags, 03:00 UTC) und manuell:

- **Build-Matrix**: alle 13 Tags (`dev`, `17`, `17-alpine`, `18–22` + `-alpine`) für `linux/amd64` + `linux/arm64`, Push nach Docker Hub (außer bei PRs)
- **Smoke-Tests**: frische Erstinstallation (`17`, `17-alpine`, `22`) muss gesunden Supervisord + HTTP 200 erreichen — siehe `tests/smoke.sh` (auch lokal: `./tests/smoke.sh <image>`)
- **Trivy-Scans**: HIGH/CRITICAL-Funde als SARIF im Code-Scanning (nur informativ, blockiert nicht)
- **Cosign-Signaturen**: keyless Sigstore-Signierung jedes gepushten Images — prüfen mit `cosign verify --certificate-identity-regexp '.*' --certificate-oidc-issuer https://token.actions.githubusercontent.com mleem97/lnxr-freepbx:<tag>`

Benötigte Repository-Secrets (*Settings → Secrets → Actions*): `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (Docker-Hub-Access-Token).

## 🐛 Fehlerbehebung

| Symptom | Wahrscheinliche Ursache / Fix |
|---------|-------------------------------|
| Container beendet sich beim Erststart | `docker logs` lesen: FreePBX-Installation braucht 2–5 Min; echte Fehler enden mit `FEHLER: …` plus Grund |
| `libasteriskssl.so.1: cannot open shared object file` | In aktuellen Images gefixt (`--libdir=/usr/lib` + `ld.so.conf` + `ldd`-Check beim Build). Tag neu pullen. |
| Web-UI `HTTP 500` | PHP-FPM läuft als `asterisk` (in aktuellen Images gefixt). Neu pullen; ggf. `freepbx_error.log` prüfen. |
| Web-UI `404` bei frischem Start | Installation nicht fertig — Logs auf den fehlschlagenden Schritt prüfen (Node/Cron/GPG/PHP-Extensions sind inzwischen alle enthalten). |
| Kein Audio / Einweg-Audio | RTP-Ports `10000–20000/udp` nicht erreichbar; NAT + externe IP in FreePBX unter *Settings → Asterisk SIP Settings* (chan_pjsip) setzen. |
| SIP-Registrierung hinter NAT scheitert | Externe Adresse, lokale Netze und Qualify in den SIP Settings konfigurieren. |
| MariaDB startet nicht | Volume-Rechte prüfen (`chown mysql:mysql` läuft beim Boot); `mariadb-supervisor.log` ansehen. |
| `supervisorctl` scheitert | Nutzt `/run/supervisord.sock` (konfiguriert); auf Debian ggf. mit `supervisorctl -c /etc/supervisor/conf.d/supervisord.conf` aufrufen. |

## 🔐 Sicherheitshinweise

- Web-UI vor dem Gang ins Internet hinter HTTPS bringen (Reverse Proxy).
- SIP/RTP-Ports müssen erreichbar sein, Web-Ports (`8080`/`8443`) aber möglichst nur aus vertrauenswürdigen Netzen.
- `MYSQL_ROOT_PASSWORD` wird aktuell **nicht angewendet** (reserviert) — MariaDB-Credentials ggf. im Container setzen.
- Images aktuell halten: `docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d`.
- Im Container läuft **kein Cron-Daemon** (nur das `crontab`-Binary für den Installer); geplante FreePBX-Jobs brauchen externen Scheduler oder Sidecar.

## 📂 Projektstruktur

```
PBX/
├── dockerfile                 # Debian single-stage (Legacy/Referenz)
├── dockerfile.optimized       # Debian multi-stage (dev, 17, 18-22)
├── dockerfile.alpine          # Alpine multi-stage (17-alpine, 18-22-alpine)
├── docker-compose.yml         # Entwicklung (Debian dev)
├── docker-compose.alpine.yml  # Alpine-Variante
├── docker-compose.prod.yml    # Produktion (per .env konfigurierbar)
├── .env.example               # Vorlage für .env / .env.prod
├── entrypoint.sh              # Erststart-Init (MariaDB, Asterisk, FreePBX-Install)
├── supervisord.conf           # Supervisor-Dienste (Debian)
├── supervisord.alpine.conf    # Supervisor-Dienste (Alpine)
├── freepbx-nginx.conf         # Nginx-Site (Debian, PHP-FPM-Socket)
├── freepbx-nginx.alpine.conf  # Nginx-Site (Alpine, PHP-FPM über 127.0.0.1:9000)
├── build.sh                   # Build- & Push-Automatisierung (dev|prod|alpine|versions|all)
├── deploy.sh                  # Produktions-Deploy-Helfer
├── Makefile                   # Kürzel (make help)
└── .github/
    └── copilot-instructions.md
```

## 🤝 Mitwirken & Support

1. Fork → Feature-Branch → committen → pushen → Pull Request.
2. Bitte das angefasste Image test-bauen (`./build.sh dev` bzw. `./build.sh alpine`).

- 🐛 **Issues:** [GitHub Issues](https://github.com/mleem97/PBX/issues)
- 🐳 **Images:** [Docker Hub](https://hub.docker.com/repository/docker/mleem97/lnxr-freepbx)
- 📖 **FreePBX-Doku:** [wiki.freepbx.org](https://wiki.freepbx.org/) · 💬 [Community-Forum](https://community.freepbx.org/) · 📞 [Asterisk-Doku](https://docs.asterisk.org/)

Lizenz: MIT — siehe [LICENSE](LICENSE).
