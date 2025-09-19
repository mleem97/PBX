# FreePBX 17 Docker Container

🚀 **Produktionsreifer FreePBX 17 + Asterisk 21 Container** für deutsche/europäische VoIP-Deployments

[![Docker Build](https://github.com/USER/REPO/actions/workflows/docker-build.yml/badge.svg)](https://github.com/USER/REPO/actions/workflows/docker-build.yml)
[![Security Scan](https://github.com/USER/REPO/actions/workflows/docker-build.yml/badge.svg)](https://github.com/USER/REPO/security/code-scanning)

## 🏗️ Architektur

**Multi-Service Container** mit supervisord:
- 🗄️ **MariaDB** (Priorität 10) - Datenbank
- ☎️ **Asterisk 21** (Priorität 20) - PBX Core
- 🐘 **PHP-FPM 8.2** (Priorität 30) - FreePBX Backend
- 🌐 **Nginx** (Priorität 40) - Web Frontend

## 🚀 Quick Start

### Voraussetzungen
- Docker & Docker Compose
- Mindestens 2GB RAM
- Freie Ports: 8080, 8443, 5060, 5061, 10000-20000

### Deployment

```bash
# Repository klonen
git clone https://github.com/YOUR_USERNAME/freepbx-docker.git
cd freepbx-docker

# Container starten
docker compose up -d

# Logs verfolgen
docker compose logs -f

# Status prüfen
docker compose ps
```

### Erste Einrichtung

1. **Web-Interface öffnen**: http://localhost:8080
2. **Admin-Benutzer erstellen** (beim ersten Besuch)
3. **Asterisk-Module installieren** (automatisch)
4. **Grundkonfiguration** über das Web-Interface

## 🔧 Konfiguration

### Port-Mapping
```yaml
ports:
  - "8080:80"          # HTTP Web-Interface
  - "8443:443"         # HTTPS Web-Interface  
  - "5060:5060/udp"    # SIP
  - "5061:5061/udp"    # Secure SIP (TLS)
  - "10000-20000:10000-20000/udp"  # RTP Media
```

### Persistente Daten
Alle wichtigen Daten werden in Named Volumes gespeichert:
- `freepbx_db` - MariaDB Datenbank (kritisch!)
- `freepbx_etc_asterisk` - Asterisk Konfiguration
- `freepbx_var_lib_asterisk` - Asterisk Runtime-Daten
- `freepbx_www` - FreePBX Web-Dateien

### Umgebungsvariablen
```bash
# Zeitzone (Standard: Europe/Berlin)
TZ=Europe/Berlin

# MySQL Root Password (automatisch generiert)
MYSQL_ROOT_PASSWORD=auto

# Asterisk User/Group IDs
ASTERISK_UID=1001
ASTERISK_GID=1001
```

## 🔄 CI/CD Pipeline

### Automatische Builds
- ✅ **Multi-Platform**: linux/amd64, linux/arm64
- ✅ **Container Registry**: GitHub Container Registry (ghcr.io)
- ✅ **Security Scanning**: Trivy Vulnerability Scanner
- ✅ **Deployment Artifacts**: Bereitstellung von deploy.sh

### Image Tags
```bash
# Latest aus main branch
ghcr.io/YOUR_USERNAME/freepbx-docker:latest

# Version Tags
ghcr.io/YOUR_USERNAME/freepbx-docker:v1.0.0
ghcr.io/YOUR_USERNAME/freepbx-docker:1.0

# Branch Tags
ghcr.io/YOUR_USERNAME/freepbx-docker:develop
```

### Produktions-Deployment
```bash
# Pre-built Image verwenden
docker pull ghcr.io/YOUR_USERNAME/freepbx-docker:latest

# Mit pre-built Image starten
export IMAGE_TAG=latest
docker compose -f docker-compose.prod.yml up -d
```

## 🛠️ Development

### Lokales Build
```bash
# Image bauen
docker compose build

# Development-Modus mit Code-Mounting
docker compose -f docker-compose.dev.yml up -d
```

### Debugging
```bash
# Container-Shell
docker exec -it freepbx bash

# Service-Status
docker exec -it freepbx supervisorctl status

# Logs anzeigen
docker exec -it freepbx tail -f /var/log/supervisord.log
docker exec -it freepbx tail -f /var/log/asterisk-supervisor.log

# Asterisk CLI
docker exec -it freepbx asterisk -r
```

## 📊 Monitoring & Logs

### Service-Überwachung
```bash
# Alle Services prüfen
docker exec -it freepbx supervisorctl status

# Service neustarten
docker exec -it freepbx supervisorctl restart asterisk
```

### Log-Locations
- **Supervisor**: `/var/log/supervisord.log`
- **Asterisk**: `/var/log/asterisk-supervisor.log`
- **MariaDB**: `/var/log/mariadb-supervisor.log`
- **PHP-FPM**: `/var/log/php8.2-fpm-supervisor.log`
- **Nginx**: `/var/log/nginx-supervisor.log`

## 🔒 Security

### Produktions-Härtung
```bash
# HTTPS aktivieren
# SSL-Zertifikate in ./ssl/ ablegen
docker compose -f docker-compose.ssl.yml up -d

# Firewall-Regeln
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 5060/udp
sudo ufw allow 5061/udp
sudo ufw allow 10000:20000/udp
```

### Backup-Strategie
```bash
# Vollständiges Backup
docker compose down
docker run --rm -v freepbx_db:/source -v $(pwd)/backup:/backup alpine tar czf /backup/freepbx-$(date +%Y%m%d).tar.gz -C /source .

# Restore
docker volume create freepbx_db
docker run --rm -v freepbx_db:/target -v $(pwd)/backup:/backup alpine tar xzf /backup/freepbx-YYYYMMDD.tar.gz -C /target
```

## 🌍 Produktions-Deployment

### Cloud-Deployment (AWS/Azure/GCP)
```bash
# Mit Cloud-spezifischen docker-compose Overrides
docker compose -f docker-compose.yml -f docker-compose.cloud.yml up -d
```

### Kubernetes Deployment
```yaml
# Helm Chart verfügbar in ./k8s/
helm install freepbx ./k8s/freepbx-chart/
```

## 🐛 Troubleshooting

### Häufige Probleme

**Container startet nicht:**
```bash
# Logs prüfen
docker compose logs

# Service-spezifische Logs
docker exec -it freepbx supervisorctl tail -f asterisk
```

**Web-Interface nicht erreichbar:**
```bash
# Nginx Status
docker exec -it freepbx supervisorctl status nginx

# Port-Binding prüfen
docker compose ps
```

**Asterisk verbindet nicht:**
```bash
# Asterisk CLI
docker exec -it freepbx asterisk -r

# SIP-Status
docker exec -it freepbx asterisk -rx "sip show peers"
```

## 📝 Changelog

### v1.0.0
- ✅ FreePBX 17 + Asterisk 21
- ✅ Multi-Platform Support
- ✅ CI/CD Pipeline
- ✅ Security Scanning
- ✅ Produktions-ready Configuration

## 🤝 Contributing

1. Fork das Repository
2. Feature Branch erstellen (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Pull Request öffnen

## 📄 License

Dieses Projekt steht unter der MIT License - siehe [LICENSE](LICENSE) Datei für Details.

## 🆘 Support

- 📖 **Dokumentation**: [FreePBX Wiki](https://wiki.freepbx.org/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/freepbx-docker/issues)
- 💬 **Community**: [FreePBX Community](https://community.freepbx.org/)

---

**⚡ Made with ❤️ for VoIP enthusiasts**