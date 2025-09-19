# Dockerfile für FreePBX 17 + Asterisk 21 auf Debian 12

FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV ASTERISK_VERSION=21
ENV FREEPBX_BRANCH=release/17.0
ENV TZ=Europe/Berlin

# --------------------------------------------------------
# System vorbereiten + Ondrej-PHP Repository hinzufügen
# --------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates lsb-release apt-transport-https software-properties-common curl gnupg2 wget git subversion \
    && curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/ondrej_php.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/ondrej-php.list \
    && apt-get update

# --------------------------------------------------------
# Abhängigkeiten installieren
# --------------------------------------------------------
RUN apt-get install -y --no-install-recommends \
    build-essential libnewt-dev libssl-dev libncurses5-dev libsqlite3-dev \
    libjansson-dev libxml2-dev uuid-dev pkg-config libedit-dev \
    unixodbc-dev libasound2-dev libogg-dev libvorbis-dev libicu-dev libcurl4-openssl-dev \
    libical-dev libneon27-dev libsrtp2-dev libspandsp-dev \
    libssl3 libssl-dev openssl libcrypto++8 libcrypto++-dev \
    mariadb-server mariadb-client \
    php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-curl php8.2-mbstring \
    php8.2-xml php8.2-gd php8.2-intl php8.2-bcmath php8.2-zip php-pear \
    nginx supervisor nodejs npm sox lame ffmpeg mpg123 \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------
# Asterisk kompilieren
# --------------------------------------------------------
RUN cd /usr/src && \
    wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz && \
    tar xvf asterisk-${ASTERISK_VERSION}-current.tar.gz && \
    cd asterisk-${ASTERISK_VERSION}*/ && \
    contrib/scripts/get_mp3_source.sh && \
    ./configure --libdir=/usr/lib/asterisk --with-pjproject-bundled --with-jansson-bundled --with-ssl && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable format_mp3 menuselect.makeopts && \
    menuselect/menuselect --enable res_crypto menuselect.makeopts && \
    make && make install && make samples && make config && ldconfig && \
    # Ensure SSL libraries are properly linked
    ldconfig /usr/lib/asterisk && \
    # Verify Asterisk installation
    /usr/sbin/asterisk -V

# --------------------------------------------------------
# Asterisk Benutzer & Rechte setzen
# --------------------------------------------------------
RUN groupadd -r asterisk && useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
    usermod -aG audio,dialout asterisk && \
    mkdir -p /var/{lib,spool,log}/asterisk && \
    chown -R asterisk:asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /etc/asterisk

# --------------------------------------------------------
# FreePBX aus Git klonen (Installation wird später im Entrypoint gemacht)
# --------------------------------------------------------
RUN cd /usr/src && \
    git clone -b ${FREEPBX_BRANCH} https://github.com/FreePBX/framework freepbx

# --------------------------------------------------------
# Konfiguration nginx + PHP-FPM vorbereiten
# --------------------------------------------------------
COPY freepbx-nginx.conf /etc/nginx/sites-available/freepbx.conf
RUN ln -s /etc/nginx/sites-available/freepbx.conf /etc/nginx/sites-enabled/freepbx.conf && \
    rm -f /etc/nginx/sites-enabled/default

# PHP-FPM Konfiguration
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.2/fpm/php.ini && \
    sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/' /etc/php/8.2/fpm/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 20M/' /etc/php/8.2/fpm/php.ini

# --------------------------------------------------------
# Entrypoint script hinzufügen
# --------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --------------------------------------------------------
# Supervisor Konfiguration kopieren
# --------------------------------------------------------
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# --------------------------------------------------------
# Ports & Volumes
# --------------------------------------------------------
EXPOSE 80 443 5060/udp 5061/udp 10000-20000/udp

VOLUME [ "/var/lib/asterisk", "/var/spool/asterisk", "/var/log/asterisk", "/etc/asterisk", "/var/www/html", "/var/lib/mysql" ]

# --------------------------------------------------------
# Container Start
# --------------------------------------------------------
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

