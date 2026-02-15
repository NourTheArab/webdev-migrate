# CHANGELOG - webdev-migrate v1.3.0 (Production Release)

**Release Date:** February 2026  
**Previous Version:** 1.2.1 (3,845 lines)  
**Final Version:** 1.3.0 (5,029 lines, +1,184)  
**Audit:** Passed Sonnet 4.5 deep audit. If that's not enough, I don't know what is.

---

## CRITICAL BUG FIXES (6/6 functions)

### Database Variable Case Mismatch — ALL functions fixed
`parse_wp_config()` returns UPPERCASE (`DB_NAME`, `DB_USER`, etc.) but operations used lowercase.

| Function | Fix Applied |
|----------|------------|
| `inventory_site()` | Uppercase vars in display, JSON, reports |
| `create_backup()` | Uppercase vars in mysqldump + manifest |
| `restore_backup()` | Credential resolution rewritten; `-h` flag; remote wp-config parsing |
| `clone_live_to_test()` | Verified correct (uses `sudo mysql` root auth) |
| `promote_test_to_live()` | Added `-h`/`-u`/`-p` credentials + error handling |
| `promote_subsite_to_standalone()` | Fixed all 4 mysql/mysqldump + parsed `$ms_db_host` |

### Additional Fixes
- Backup verification (file exists + non-empty + size shown)
- mysqldump flag spacing: `-h "$HOST" -u "$USER"` (all functions)
- Removed redundant config re-parse in `clone_live_to_test`
- Dead code cleanup (`set -e` after `return 0`)

---

## SAFETY ENHANCEMENTS

| Feature | Description |
|---------|------------|
| Pre-migration validation | 3-point check: WP-CLI, DB health, write access |
| Rollback backup | Creates backup, handles failure, shows restore path |
| Password helper | `get_db_password_with_help()` in `restore_backup()` |
| Server name validation | Empty, special chars, reserved, duplicate checks |
| Temp dir cleanup | `trap ... RETURN` for transfer temp |
| Ping fallback | TCP port 22 when ping blocked |
| **Backup size estimation** | Shows files + DB size before backup; warns if >1GB |
| **Backup retention** | Auto-cleans backups older than 30 days (configurable) |

---

## NEW FEATURES

- Multi-server session management (associative arrays, profiles)
- Server profiles (`~/.webdev-migrate/servers/`)
- SSH ProxyJump in `remote_exec`/`remote_copy` (with legacy fallback)
- 5-point connection testing (+ TCP fallback)
- Cross-server migration wizard (6 steps with validation + rollback)
- Two-tier menu (Scope → Local / Multi-Server)
- CLI: `multi-server`, `add-server`, `test-connection`, `server-profiles`
- Configurable `BACKUP_RETENTION_DAYS` (default: 30, set in `~/.webdev-migrate.conf`)

---

## UNCHANGED

- `set -o pipefail` (no `-eo`) · `$((var + 1))` (no `((var++))`)
- All v1.2.1 UX: startup tips, inline help, sudo check, quick reference, site discovery
- Lock system, dry-run, confirmation strings, all existing CLI commands

---

## TESTING

```bash
bash -n webdev-migrate                    # Syntax
sudo webdev-migrate list-all-sites        # Regression
sudo webdev-migrate backup /var/www/wordpress-testing-fieldscience fieldscience test  # Size estimate + retention
sudo webdev-migrate restore /srv/backups/wp/fieldscience/test/TIMESTAMP /tmp/test-restore
sudo webdev-migrate add-server web 192.168.1.10 njalshe23 --proxy jumphost.cs.earlham.edu
sudo webdev-migrate test-connection web
sudo webdev-migrate multi-server
```

## DEPLOYMENT

```bash
cd /tmp && git clone https://code.cs.earlham.edu/njalshe23/webdev-migrate.git
bash -n webdev-migrate/webdev-migrate
sudo cp webdev-migrate/webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate
```

```bash
git add webdev-migrate
git commit -m "v1.3.0 - Production release: DB fixes + multi-server + safety"
git tag -a v1.3.0 -m "Version 1.3.0 - Production ready"
git push origin main --tags
```