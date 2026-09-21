#!/bin/bash
set -e

# Shared-Library-Pfad sicherstellen (Fix fuer Issue #1:
# "libasteriskssl.so.1: cannot open shared object file")
if [ -d /usr/lib/asterisk ] && ! grep -qr "/usr/lib/asterisk" /etc/ld.so.conf.d/ 2>/dev/null; then
    echo "/usr/lib/asterisk" > /etc/ld.so.conf.d/asterisk.conf
fi
ldconfig || true

# Fruehzeitiger Preflight-Check mit verstaendlicher Fehlermeldung
if [ ! -x /usr/sbin/asterisk ]; then
    echo "FEHLER: /usr/sbin/asterisk nicht gefunden. Image neu bauen." >&2
    exit 1
fi
if ldd /usr/sbin/asterisk 2>/dev/null | grep -q "not found"; then
    echo "FEHLER: Asterisk Shared Libraries fehlen:" >&2
    ldd /usr/sbin/asterisk | grep "not found" >&2 || true
    echo "Tipp: Image neu bauen (Fix: --libdir=/usr/lib + ld.so.conf). Siehe Issue #1." >&2
    exit 1
fi

# Zeitzone falls nötig
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
echo "Europe/Berlin" > /etc/timezone

# Stelle sicher, dass MySQL-Verzeichnisse korrekte Berechtigungen haben
chown -R mysql:mysql /var/lib/mysql
chown -R asterisk:asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /etc/asterisk

# Falls MySQL noch nicht initialisiert
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# MariaDB temporär starten für FreePBX Installation
echo "Starting MariaDB temporarily for setup..."
/usr/sbin/mariadbd --user=mysql --skip-networking --socket=/tmp/mysql_temp.sock &
MYSQL_PID=$!

# Warten, bis MariaDB bereit ist
until mysqladmin ping --socket=/tmp/mysql_temp.sock --silent; do
  echo "Waiting for MariaDB..."
  sleep 2
done

echo "MariaDB started successfully"

# Falls FreePBX noch nicht installiert
if [ ! -f /var/www/html/admin/config.php ]; then
    echo "Erstinstallation FreePBX wird ausgeführt"
    
    # Starte Asterisk temporär für FreePBX Installation
    echo "STARTING ASTERISK FOR INSTALLATION"
    if ! /usr/sbin/asterisk -U asterisk -G asterisk; then
        echo "FEHLER: Asterisk startete nicht. Library-Check:" >&2
        ldd /usr/sbin/asterisk >&2 || true
        exit 1
    fi
    
    # Warte bis Asterisk läuft
    sleep 5
    
    cd /usr/src/freepbx
    ./install -n --dbhost=localhost --dbsock=/tmp/mysql_temp.sock
    
    # Stoppe Asterisk nach Installation
    /usr/sbin/asterisk -rx "core stop now" || true
    sleep 3
fi

# Stoppe temporäre MariaDB
kill $MYSQL_PID || true
sleep 3

echo "Setup completed, starting supervisord..."

# Supervisord startet alle Services
exec "$@"

