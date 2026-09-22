# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.0.0] - 2026-09-22

First tagged release: production-ready FreePBX 17 + Asterisk images on Debian and Alpine, with CI, docs and tooling.

### Added
- Alpine-based images (`17-alpine`, `18-alpine`–`22-alpine`, Alpine 3.20, musl) — ~20% smaller than Debian
- Asterisk version tags `18`–`22` (+ `-alpine` variants); `18`/`19` pinned to last EOL releases (18.26.4 / 19.8.1)
- `ASTERISK_VERSION` / `ASTERISK_TARBALL_URL` build args; `./build.sh versions` and `make build-versions` / `push-versions`
- GitHub Actions CI (`ci.yml`): multi-arch builds (amd64+arm64) on push, weekly security rebuilds, boot smoke tests, Trivy scans (SARIF), keyless Cosign signing
- Boot smoke test script (`tests/smoke.sh`), usable in CI and locally
- Tested `backup.sh` / `restore.sh` for Docker volumes
- Portainer App Template (`portainer-template.json`, 1-click deploy from this repo)
- German README (`README.de.md`); English README rewritten (setup, all env vars, nginx/Traefik/Caddy reverse-proxy examples, TLS, tags)
- Real Web-UI screenshot (`docs/screenshots/01-login.png`)
- `CHANGELOG.md` (this file)
- `supervisorctl` works out of the box (unix_http_server socket in both supervisor configs)
- Missing `.env.example` added; `docker-compose.alpine.yml` added

### Fixed
- **Issue #1** (`libasteriskssl.so.1: cannot open shared object file`): `--libdir=/usr/lib` + persistent `ld.so.conf` entry (Debian); build-time `ldd` verification; entrypoint preflight check
- Nginx → PHP-FPM socket path (`/run/php/php8.2-fpm.sock`); Alpine uses TCP `127.0.0.1:9000`
- `docker-compose.yml` now names the lowercase `dockerfile` explicitly
- Production healthcheck fixed (`CMD-SHELL` form)
- `deploy.sh`: shebang position, env validation aligned with compose file
- PHP-FPM runs as `asterisk:asterisk` (fixes HTTP 500 on `/etc/freepbx.conf`, mode 660)
- FreePBX installer call fixed (removed non-existent `--dbsock` option; temp socket via CLI php.ini with restore)
- Patched upstream installer bug (exit 1 despite success) at build time
- `mkdir` brace expansion replaced (dash/BusyBox incompatible)
- Optimized builder: missing `subversion` dep, parallel `make -j`
- Optimized runtime: Debian 12 package names (`libncurses6`, `libuuid1`, `libodbc2`), complete multi-stage `COPY` set, `nodejs`, `cron`, `supervisorctl` symlink
- Entrypoint hardened: portable binary lookup (Debian/Alpine paths), install-marker verification, proper exit codes

### Musl/Alpine port (Asterisk compiled with musl libc)
- BSD `__P`/`__BEGIN_DECLS` compat for bundled Berkeley DB, `ALLPERMS` define, `compat.h` musl block (`ast_expr2.y` fix)
- Pre-included system headers before `MALLOC_DEBUG` / `astmm.h` poison macros (musl declares `calloc`/`free` in `<sched.h>`)
- Recursive static mutexes via constructor init (`lock.h`, musl has no `PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP`)
- `-rdynamic` linking (musl resolves executable symbols for modules only then)
- Runtime additions: `bash`, `runuser` (util-linux-login), `gnupg`, GNU `findutils` (`-xtype`), PHP `sysvsem/shm/pcntl` extensions, `nodejs`

## [0.1.0] - 2026-09-21 (unreleased work leading to 1.0.0)

- Initial FreePBX 17 + Asterisk 21 Docker setup (multi-service Supervisor container)
- Build automation (`build.sh`, `Makefile`), dev/prod Compose files, docs
