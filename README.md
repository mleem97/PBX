# FreePBX 17 Docker Container

🚀 **Production-ready FreePBX 17 + Asterisk 21 Container** for VoIP deployments

![Docker Pulls](https://img.shields.io/docker/pulls/mleem97/lnxr-freepbx)
![Docker Image Size](https://img.shields.io/docker/image-size/mleem97/lnxr-freepbx/17)
![Docker Image Version](https://img.shields.io/docker/v/mleem97/lnxr-freepbx?sort=semver)
[![GitHub](https://img.shields.io/github/license/mleem97/PBX)](https://github.com/mleem97/PBX/blob/main/LICENSE)

## 🏗️ Architecture

**Multi-Service Container** managed by supervisor:
- 🗄️ **MariaDB** (Priority 10) - Database backend
- ☎️ **Asterisk 21** (Priority 20) - PBX core engine
- 🐘 **PHP-FPM 8.2** (Priority 30) - FreePBX web backend
- 🌐 **Nginx** (Priority 40) - Web server frontend

Built from source with specific optimizations for VoIP workloads.

## 🚀 Quick Start

### From Docker Hub (Recommended)

```bash
# Pull and run production image
docker run -d --name freepbx \
  -p 8080:80 -p 5060:5060/udp -p 10000-20000:10000-20000/udp \
  --restart unless-stopped \
  mleem97/lnxr-freepbx:17

# Access web interface at http://localhost:8080
```

### Development Setup

```bash
# Clone repository
git clone https://github.com/mleem97/PBX.git
cd PBX

# Build and start development container
./build.sh dev
docker-compose up -d

# Or use Makefile
make dev-deploy
```

## 🔧 Configuration

### Available Images

- **Production**: `mleem97/lnxr-freepbx:17` (latest stable)
- **Development**: `mleem97/lnxr-freepbx:dev` (latest build)

### Port Configuration
```yaml
ports:
  - "8080:80"          # HTTP Web Interface
  - "8443:443"         # HTTPS Web Interface  
  - "5060:5060/udp"    # SIP Signaling
  - "5061:5061/udp"    # Secure SIP (TLS)
  - "10000-20000:10000-20000/udp"  # RTP Media Streams
```

### Persistent Data Volumes
All critical data is stored in named volumes:
- `freepbx_db` - MariaDB database (critical!)
- `freepbx_etc_asterisk` - Asterisk configuration
- `freepbx_var_lib_asterisk` - Asterisk runtime data
- `freepbx_www` - FreePBX web files
- `freepbx_var_log` - System logs
- `freepbx_spool` - Call processing data

### Environment Variables
```bash
# Timezone (default: Europe/Berlin)
TZ=Europe/Berlin

# MySQL Root Password (for production)
MYSQL_ROOT_PASSWORD=your_secure_password
```

## 🐳 Docker Compose Examples

### Production Setup
```yaml
version: '3.8'
services:
  freepbx:
    image: mleem97/lnxr-freepbx:17
    container_name: lnxr-freepbx-prod
    restart: unless-stopped
    ports:
      - "8080:80"
      - "8443:443"
      - "5060:5060/udp"
      - "5061:5061/udp"
      - "10000-20000:10000-20000/udp"
    environment:
      - TZ=Europe/Berlin
      - MYSQL_ROOT_PASSWORD=your_secure_password
    volumes:
      - freepbx_db:/var/lib/mysql
      - freepbx_config:/etc/asterisk
      - freepbx_www:/var/www/html
      - freepbx_logs:/var/log/asterisk
      # SSL certificates (optional)
      - ./ssl:/etc/ssl/certs/freepbx:ro

volumes:
  freepbx_db:
  freepbx_config:
  freepbx_www:
  freepbx_logs:
```

### Development Setup
```yaml
version: '3.8'
services:
  freepbx:
    build: .
    image: lnxr-freepbx:dev
    container_name: lnxr-freepbx-dev
    ports:
      - "8080:80"
      - "5060:5060/udp"
      - "10000-20000:10000-20000/udp"
    environment:
      - TZ=Europe/Berlin
```

## � Build & Development

### Build Tools

This project includes automated build tools:

```bash
# Build development image
./build.sh dev

# Build production image
./build.sh prod

# Build both and push to Docker Hub
./build.sh all --push

# Using Makefile
make build-all       # Build both images
make push-all        # Build and push to Docker Hub
make dev-deploy      # Build and start development
```

### Development Workflow
```bash
# Start development environment
make dev-deploy

# View logs
make logs

# Open shell in container
make shell-dev

# Access Asterisk CLI
make asterisk-cli

# Check container status
make status
```

### Image Optimization

For production deployments, consider using the optimized multi-stage Dockerfile:

```bash
# Build with optimized Dockerfile (smaller image size)
docker build -f dockerfile.optimized -t lnxr-freepbx:optimized .
```

## 🔍 Monitoring & Debugging

### Container Health Checks
```bash
# Check all services
docker exec -it lnxr-freepbx supervisorctl status

# Check individual service
docker exec -it lnxr-freepbx supervisorctl status asterisk

# Restart a service
docker exec -it lnxr-freepbx supervisorctl restart asterisk
```

### Accessing Logs
```bash
# Container logs
docker logs lnxr-freepbx

# Service-specific logs
docker exec -it lnxr-freepbx tail -f /var/log/supervisord.log
docker exec -it lnxr-freepbx tail -f /var/log/asterisk-supervisor.log
docker exec -it lnxr-freepbx tail -f /var/log/mariadb-supervisor.log

# Using Makefile
make logs          # Development logs
make logs-prod     # Production logs
```

### Asterisk CLI Access
```bash
# Open Asterisk CLI
docker exec -it lnxr-freepbx asterisk -r

# Common Asterisk commands
asterisk -rx "core show channels"
asterisk -rx "sip show peers"
asterisk -rx "database show"
```

## 🔒 Security & Production

### SSL/HTTPS Setup
```bash
# Place SSL certificates in ./ssl/ directory
mkdir ssl
cp your-cert.pem ssl/
cp your-key.pem ssl/

# Mount SSL certificates
docker run -d --name freepbx \
  -v ./ssl:/etc/ssl/certs/freepbx:ro \
  -p 8443:443 \
  mleem97/lnxr-freepbx:17
```

### Firewall Configuration
```bash
# Allow required ports
sudo ufw allow 8080/tcp    # HTTP
sudo ufw allow 8443/tcp    # HTTPS
sudo ufw allow 5060/udp    # SIP
sudo ufw allow 5061/udp    # Secure SIP
sudo ufw allow 10000:20000/udp  # RTP Range
```

### Backup Strategy
```bash
# Backup all volumes
docker run --rm \
  -v freepbx_db:/source/db \
  -v freepbx_etc_asterisk:/source/config \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/freepbx-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore from backup
docker run --rm \
  -v freepbx_db:/target/db \
  -v freepbx_etc_asterisk:/target/config \
  -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/freepbx-backup-YYYYMMDD.tar.gz -C /target
```

## 🐛 Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check logs
docker logs lnxr-freepbx

# Check service status
docker exec -it lnxr-freepbx supervisorctl status
```

**Web interface not accessible:**
```bash
# Check Nginx status
docker exec -it lnxr-freepbx supervisorctl status nginx

# Check port binding
docker ps -a | grep lnxr-freepbx
```

**Asterisk connection issues:**
```bash
# Access Asterisk CLI
docker exec -it lnxr-freepbx asterisk -r

# Check SIP status
asterisk -rx "sip show peers"
asterisk -rx "core show channels"
```

**Database issues:**
```bash
# Check MariaDB status
docker exec -it lnxr-freepbx supervisorctl status mysqld

# Access MySQL CLI
docker exec -it lnxr-freepbx mysql -u root -p
```

### Performance Optimization

- **Memory**: Minimum 2GB RAM recommended, 4GB+ for production
- **Storage**: Use SSD storage for database volumes
- **Network**: Ensure RTP port range (10000-20000) is properly configured

## 📂 Project Structure

```
PBX/
├── dockerfile                 # Main Dockerfile
├── dockerfile.optimized      # Multi-stage optimized Dockerfile
├── docker-compose.yml        # Development compose
├── docker-compose.prod.yml   # Production compose
├── entrypoint.sh             # Container initialization script
├── supervisord.conf          # Service management configuration
├── freepbx-nginx.conf       # Nginx web server configuration
├── build.sh                 # Build automation script
├── Makefile                 # Development shortcuts
├── .env.example             # Environment variables template
└── .github/
    └── copilot-instructions.md  # AI coding guidelines
```

## 🏷️ Available Tags

| Tag | Description | Use Case |
|-----|-------------|----------|
| `17`, `latest` | Latest stable FreePBX 17 release | Production deployments |
| `dev` | Development build from main branch | Development, testing |

Pull from Docker Hub:
```bash
docker pull mleem97/lnxr-freepbx:17    # Production
docker pull mleem97/lnxr-freepbx:dev   # Development
```

## 📝 Features

- ✅ **FreePBX 17** with latest web interface
- ✅ **Asterisk 21** with MP3 and crypto support
- ✅ **Multi-service orchestration** via supervisor
- ✅ **Persistent data volumes** for configuration and call data
- ✅ **Production-ready** with health checks and logging
- ✅ **Docker Hub integration** with automated builds
- ✅ **European timezone** support (Europe/Berlin default)
- ✅ **SSL/HTTPS** ready configuration
- ✅ **Development tools** with build automation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Documentation

- � **Docker Hub**: [mleem97/lnxr-freepbx](https://hub.docker.com/r/mleem97/lnxr-freepbx)
- 📖 **FreePBX Documentation**: [FreePBX Wiki](https://wiki.freepbx.org/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/mleem97/PBX/issues)
- 💬 **Community**: [FreePBX Community Forum](https://community.freepbx.org/)
- 📞 **Asterisk**: [Asterisk Documentation](https://docs.asterisk.org/)

## ⭐ Acknowledgments

- FreePBX Team for the amazing PBX software
- Asterisk Team for the robust telephony engine
- Docker Community for containerization best practices

---

**⚡ Made with ❤️ for VoIP enthusiasts**

**Ready to deploy your FreePBX? Pull from Docker Hub and get started in minutes!**

```bash
docker pull mleem97/lnxr-freepbx:17
```