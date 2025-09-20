# Docker Hub Repository Metadata für mleem97/lnxr-freepbx

## Repository Description (Short)
FreePBX 17 + Asterisk 21 containerized PBX system with web management interface. Complete VoIP solution in Docker.

## Repository Description (Full)
A complete FreePBX 17 + Asterisk 21 containerized PBX system running on Debian 12. This Docker image provides a fully functional VoIP phone system with web-based management interface, designed for German/European deployment.

**Features:**
- FreePBX 17 web interface for easy PBX management
- Asterisk 21 PBX engine with MP3 and crypto support
- MariaDB database backend
- Nginx + PHP-FPM web server stack
- Supervisor for multi-service orchestration
- Persistent data volumes for configuration and call data
- Ready for production deployment
- Timezone: Europe/Berlin (configurable)

**Supported Tags:**
- `17`, `latest` - Production-ready FreePBX 17 release
- `dev` - Development build with latest changes

**Quick Start:**
```bash
docker run -d --name freepbx \
  -p 8080:80 -p 5060:5060/udp \
  -p 10000-20000:10000-20000/udp \
  mleem97/lnxr-freepbx:17
```

Access web interface at http://localhost:8080

## Categories (Select appropriate ones on Docker Hub)
- Application Infrastructure
- Networking
- Business Software
- Communication

## Tags/Keywords
freepbx, asterisk, pbx, voip, sip, telephony, communication, debian, nginx, php, mariadb, docker, container

## Links
- **Source Code:** https://github.com/mleem97/PBX
- **Documentation:** https://github.com/mleem97/PBX#readme
- **Issues:** https://github.com/mleem97/PBX/issues

## Build Information
**Dockerfile:** Available in GitHub repository
**Automated Build:** Manual builds with versioned releases
**Base Image:** debian:12
**Architecture:** linux/amd64

## Usage Examples

### Development
```bash
docker-compose up -d
```

### Production
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

### With Docker Compose
```yaml
version: '3.8'
services:
  freepbx:
    image: mleem97/lnxr-freepbx:17
    container_name: lnxr-freepbx
    restart: unless-stopped
    ports:
      - "8080:80"
      - "5060:5060/udp"
      - "10000-20000:10000-20000/udp"
    environment:
      - TZ=Europe/Berlin
    volumes:
      - freepbx_data:/var/lib/mysql
      - freepbx_config:/etc/asterisk
volumes:
  freepbx_data:
  freepbx_config:
```

## Supported Environment Variables
- `TZ` - Timezone (default: Europe/Berlin)
- `MYSQL_ROOT_PASSWORD` - MySQL root password for production

## Exposed Ports
- `80/tcp` - FreePBX web interface (HTTP)
- `443/tcp` - FreePBX web interface (HTTPS)
- `5060/udp` - SIP signaling
- `5061/udp` - Secure SIP (TLS)
- `10000-20000/udp` - RTP media streams

## Volumes
- `/var/lib/mysql` - MariaDB database
- `/etc/asterisk` - Asterisk configuration
- `/var/lib/asterisk` - Asterisk runtime data
- `/var/www/html` - FreePBX web files
- `/var/log/asterisk` - Asterisk logs
- `/var/spool/asterisk` - Call processing data

## License
MIT License - see LICENSE file for details

## Maintainer
mleem97

## Support
For issues and support, please visit: https://github.com/mleem97/PBX/issues