#!/bin/bash
set -e

# Shared-Library-Pfad sicherstellen (nur glibc/Debian; musl/Alpine braucht kein ldconfig)
# Fix fuer Issue #1: "libasteriskssl.so.1: cannot open shared object file"
if command -v ldconfig >/dev/null 2>&1 && [ -d /etc/ld.so.conf.d ]; then
    if [ -d /usr/lib/asterisk ] && ! grep -qr "/usr/lib/asterisk" /etc/ld.so.conf.d/ 2>/dev/null; then
        echo "/usr/lib/asterisk" > /etc/ld.so.conf.d/asterisk.conf
    fi
    ldconfig || true
fi

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

# Binary-Pfade portabel aufloesen (Debian: /usr/sbin, Alpine: /usr/bin)
MARIADBD_BIN=$(command -v mariadbd || echo /usr/sbin/mariadbd)
MYSQL_INSTALL_DB=$(command -v mysql_install_db || command -v mariadb-install-db)

# Stelle sicher, dass MySQL-Verzeichnisse korrekte Berechtigungen haben
chown -R mysql:mysql /var/lib/mysql
chown -R asterisk:asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /etc/asterisk

# Socket-Verzeichnis fuer den MariaDB-Daemon unter supervisord
# (auf Alpine existiert /run/mysqld nicht von Haus aus)
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Falls MySQL noch nicht initialisiert
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL database..."
    $MYSQL_INSTALL_DB --user=mysql --datadir=/var/lib/mysql
fi

# MariaDB temporär starten für FreePBX Installation
echo "Starting MariaDB temporarily for setup..."
$MARIADBD_BIN --user=mysql --skip-networking --socket=/tmp/mysql_temp.sock &
MYSQL_PID=$!

# Warten, bis MariaDB bereit ist
until mysqladmin ping --socket=/tmp/mysql_temp.sock --silent; do
  echo "Waiting for MariaDB..."
  sleep 2
done

echo "MariaDB started successfully"

# FreePBX 17 install kennt keine --dbsock Option; mit --dbhost=localhost
# nutzt PHP (mysqlnd) mysqli.default_socket. Wir zeigen den CLI-php.inis
# temporaer auf unseren Install-Socket (gilt auch fuer Subprozesse wie
# fwconsole) und stellen danach den Originalzustand wieder her.
# Aufruf: set_php_install_socket on  -> Temp-Socket setzen
#         set_php_install_socket      -> wieder entfernen (kein Argument!)
set_php_install_socket() {
    for ini in /etc/php/8.2/cli/php.ini /etc/php82/php.ini; do
        [ -f "$ini" ] || continue
        sed -i '/^mysqli.default_socket *= *\/tmp\/mysql_temp.sock$/d; /^pdo_mysql.default_socket *= *\/tmp\/mysql_temp.sock$/d' "$ini"
        if [ "$1" = "on" ]; then
            grep -q '^mysqli.default_socket' "$ini" \
                && sed -i 's|^mysqli.default_socket.*|mysqli.default_socket = /tmp/mysql_temp.sock|' "$ini" \
                || echo 'mysqli.default_socket = /tmp/mysql_temp.sock' >> "$ini"
            grep -q '^pdo_mysql.default_socket' "$ini" \
                && sed -i 's|^pdo_mysql.default_socket.*|pdo_mysql.default_socket = /tmp/mysql_temp.sock|' "$ini" \
                || echo 'pdo_mysql.default_socket = /tmp/mysql_temp.sock' >> "$ini"
        fi
    done
}

# Falls FreePBX noch nicht installiert
if [ ! -f /var/www/html/admin/config.php ]; then
    echo "Erstinstallation FreePBX wird ausgeführt"

    set_php_install_socket on

    # Starte Asterisk temporär für FreePBX Installation
    echo "STARTING ASTERISK FOR INSTALLATION"
    if ! /usr/sbin/asterisk -U asterisk -G asterisk; then
        echo "FEHLER: Asterisk startete nicht. Library-Check:" >&2
        ldd /usr/sbin/asterisk >&2 || true
        set_php_install_socket
        exit 1
    fi

    # Warte bis Asterisk läuft
    sleep 5

    cd /usr/src/freepbx
    INSTALL_RC=0
    ./install -n --dbhost=localhost || INSTALL_RC=$?

    # PHP-Socket-Einstellung wieder zuruecksetzen (Laufzeit nutzt den
    # Standard-Socket /run/mysqld/mysqld.sock bzw. /var/run/...)
    set_php_install_socket

    if [ $INSTALL_RC -ne 0 ]; then
        echo "FEHLER: FreePBX Installation fehlgeschlagen (Exit $INSTALL_RC)." >&2
        exit $INSTALL_RC
    fi

    # Verifizieren: der Installer meldet Erfolg teils auch bei Abbruch
    # (z.B. fehlendes NodeJS -> return false -> Exit 0). Ohne diese
    # Marker ist die Installation unvollstaendig.
    if [ ! -f /var/www/html/admin/config.php ] || [ ! -f /etc/freepbx.conf ]; then
        echo "FEHLER: FreePBX Installation unvollstaendig (Marker fehlen: /var/www/html/admin/config.php, /etc/freepbx.conf)." >&2
        exit 1
    fi

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


# rebuilt: force COPY layer refresh
