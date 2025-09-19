# FreePBX 17 Docker Container - AI Coding Instructions

## Project Overview
This is a **FreePBX 17 + Asterisk 21** containerized PBX system running on Debian 12. The project builds a complete VoIP phone system in Docker with web-based management interface, designed for German/European deployment (timezone: Europe/Berlin).

## Architecture & Service Dependencies

### Multi-Service Container Pattern
Uses **supervisor** to manage 4 critical services in priority order:
1. **MariaDB** (priority 10) - Database backend
2. **Asterisk** (priority 20) - PBX core engine  
3. **PHP-FPM** (priority 30) - FreePBX web interface backend
4. **Nginx** (priority 40) - Web server frontend

**Critical**: Services must start in this exact order due to dependencies. Asterisk requires MariaDB, FreePBX requires both.

### Port Configuration
- `8080:80` - FreePBX web interface (HTTP)
- `8443:443` - FreePBX web interface (HTTPS) 
- `5060:5060/udp` - SIP signaling
- `5061:5061/udp` - Secure SIP (TLS)
- `10000-20000:10000-20000/udp` - RTP media streams (large range for concurrent calls)

### Volume Strategy
Named volumes for persistent data across container rebuilds:
- `freepbx_etc_asterisk` - Asterisk configuration
- `freepbx_var_lib_asterisk` - Asterisk runtime data
- `freepbx_db` - MariaDB data (most critical)
- `freepbx_www` - FreePBX web files
- `freepbx_var_log`, `freepbx_spool` - Logs and call processing

## Key Development Patterns

### Dockerfile Build Pattern
- **Source compilation**: Asterisk built from source with specific modules (`format_mp3`, `res_crypto`)
- **External PHP repo**: Uses Ondrej Sury repository for PHP 8.2 on Debian 12
- **Bundle strategy**: Includes `--with-pjproject-bundled --with-jansson-bundled` for dependency isolation

### First-Run Installation Logic
The `entrypoint.sh` implements a **complex initialization sequence**:

```bash
# Key pattern: Temporary MySQL socket for installation
/usr/sbin/mariadbd --user=mysql --skip-networking --socket=/tmp/mysql_temp.sock &

# FreePBX installation requires running Asterisk
if [ ! -f /var/www/html/admin/config.php ]; then
    /usr/sbin/asterisk -U asterisk -G asterisk
    cd /usr/src/freepbx
    ./install -n --dbhost=localhost --dbsock=/tmp/mysql_temp.sock
fi
```

**Critical**: Never modify this sequence - FreePBX installation is fragile and requires exact service orchestration.

### Configuration File Patterns

#### Nginx Configuration (`freepbx-nginx.conf`)
- **PHP-FPM socket**: Uses Unix socket `/run/php/8.2/fpm.sock` (not TCP)
- **Large uploads**: `client_max_body_size 20M` for firmware/music uploads
- **Path handling**: `try_files $uri $uri/ /index.php?$args` for FreePBX routing

#### Supervisor Priority System
Services have **strict priority ordering** in `supervisord.conf`:
- MySQL (10) → Asterisk (20) → PHP-FPM (30) → Nginx (40)
- `startsecs=10` prevents rapid restart loops
- All services log to `/var/log/*-supervisor.log`

## Development Workflows

### Container Management
```bash
# Build with specific tag matching FreePBX version
docker-compose build  # Creates lnxr-freepbx:17

# First run (triggers FreePBX installation)
docker-compose up -d

# Access web interface
http://localhost:8080

# Check service status inside container
docker exec -it lnxr-freepbx supervisorctl status
```

### Debugging Service Issues
```bash
# Check supervisor logs
docker exec -it lnxr-freepbx tail -f /var/log/supervisord.log

# Check individual service logs
docker exec -it lnxr-freepbx tail -f /var/log/asterisk-supervisor.log
docker exec -it lnxr-freepbx tail -f /var/log/mariadb-supervisor.log

# Asterisk CLI access
docker exec -it lnxr-freepbx asterisk -r
```

### Configuration Changes
- **Asterisk config**: Edit files in `freepbx_etc_asterisk` volume, restart Asterisk service
- **Web config**: Changes persist in `freepbx_www` and `freepbx_db` volumes
- **Container config**: Modify source files and rebuild image

## Critical Constraints

### Security & User Management
- **Asterisk user**: All Asterisk processes run as `asterisk:asterisk` user (not root)
- **File permissions**: `/var/lib/asterisk`, `/var/spool/asterisk`, `/var/log/asterisk` must be owned by `asterisk:asterisk`
- **MySQL**: Runs as `mysql` user with proper datadir ownership

### Version Dependencies
- **PHP 8.2**: Required for FreePBX 17 compatibility
- **Asterisk 21**: Specific version matched to FreePBX release branch `release/17.0`
- **MariaDB**: Use MariaDB (not MySQL) for best FreePBX compatibility

### Network Considerations
- **RTP range**: The `10000-20000/udp` range must be contiguous for proper audio
- **SIP protocols**: Both TCP/UDP 5060 and TLS 5061 are exposed
- **NAT handling**: May require additional configuration for external SIP clients

When modifying this project, always consider the service startup dependencies and avoid breaking the first-run installation sequence.