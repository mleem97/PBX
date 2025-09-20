# FreePBX 17 + Asterisk 21 Docker Container

![Docker Pulls](https://img.shields.io/docker/pulls/mleem97/lnxr-freepbx)
![Docker Image Size](https://img.shields.io/docker/image-size/mleem97/lnxr-freepbx/17)
![Docker Image Version](https://img.shields.io/docker/v/mleem97/lnxr-freepbx?sort=semver)

A complete **FreePBX 17 + Asterisk 21** containerized PBX system with web-based management interface. Ready for production VoIP deployments.

## ⚡ Quick Start

```bash
# Basic setup
docker run -d --name freepbx \
  -p 8080:80 -p 5060:5060/udp -p 10000-20000:10000-20000/udp \
  mleem97/lnxr-freepbx:17

# Access web interface
open http://localhost:8080
```

## 🐳 Supported Tags

- `17`, `latest` - Production FreePBX 17 release
- `dev` - Development build

## 📦 What's Included

- **FreePBX 17** - Complete web-based PBX management
- **Asterisk 21** - PBX engine with MP3 & crypto support  
- **MariaDB** - Database backend
- **Nginx + PHP-FPM** - Web server stack
- **Supervisor** - Multi-service orchestration

## 🚀 Production Setup

### Docker Compose (Recommended)

```yaml
version: '3.8'
services:
  freepbx:
    image: mleem97/lnxr-freepbx:17
    container_name: lnxr-freepbx
    restart: unless-stopped
    ports:
      - "8080:80"
      - "8443:443"
      - "5060:5060/udp"
      - "5061:5061/udp"
      - "10000-20000:10000-20000/udp"
    environment:
      - TZ=Europe/Berlin
    volumes:
      - freepbx_db:/var/lib/mysql
      - freepbx_config:/etc/asterisk
      - freepbx_www:/var/www/html
      - freepbx_logs:/var/log/asterisk

volumes:
  freepbx_db:
  freepbx_config:
  freepbx_www:
  freepbx_logs:
```

### Docker Run

```bash
docker run -d --name lnxr-freepbx-prod \
  --restart unless-stopped \
  -p 8080:80 -p 8443:443 \
  -p 5060:5060/udp -p 5061:5061/udp \
  -p 10000-20000:10000-20000/udp \
  -v freepbx_data:/var/lib/mysql \
  -v freepbx_config:/etc/asterisk \
  -e TZ=Europe/Berlin \
  mleem97/lnxr-freepbx:17
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `Europe/Berlin` | Container timezone |
| `MYSQL_ROOT_PASSWORD` | *(empty)* | MySQL root password |

### Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `80` | TCP | FreePBX web interface (HTTP) |
| `443` | TCP | FreePBX web interface (HTTPS) |
| `5060` | UDP | SIP signaling |
| `5061` | UDP | Secure SIP (TLS) |
| `10000-20000` | UDP | RTP media streams |

### Volumes

| Mount Point | Description |
|-------------|-------------|
| `/var/lib/mysql` | MariaDB database |
| `/etc/asterisk` | Asterisk configuration |
| `/var/lib/asterisk` | Asterisk runtime data |
| `/var/www/html` | FreePBX web files |
| `/var/log/asterisk` | Asterisk logs |

## 🔍 Health Check

```bash
# Check container status
docker exec -it freepbx supervisorctl status

# Access Asterisk CLI
docker exec -it freepbx asterisk -r

# View logs
docker logs freepbx
```

## 📚 Documentation

- **Source Code:** [GitHub Repository](https://github.com/mleem97/PBX)
- **Issues:** [Report Issues](https://github.com/mleem97/PBX/issues)
- **FreePBX Documentation:** [Official Docs](https://wiki.freepbx.org/)

## ⚠️ Important Notes

- **First Run:** Initial setup takes 2-5 minutes
- **Memory:** Minimum 2GB RAM recommended
- **Network:** Configure firewall for SIP/RTP ports
- **SSL:** Mount certificates to `/etc/ssl/certs/freepbx`

## 🤝 Support

For technical support and feature requests:
- [GitHub Issues](https://github.com/mleem97/PBX/issues)
- [FreePBX Community](https://community.freepbx.org/)

---

**License:** Check repository for license information  
**Maintainer:** mleem97