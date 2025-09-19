#!/bin/bash
set -e

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
    /usr/sbin/asterisk -U asterisk -G asterisk
    
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

