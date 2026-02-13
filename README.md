# webdev-migrate v1.2.0

**Production WordPress Management Tool - Beginner-Proof | Made by Nour**

Version 1.2.0 | 3,420 lines | Finished on February 13, 2026

---

**A Note:**
- This was a passion project I started in frustration from the various incomplete and often faulty migration scripts we had. The purpose of this project is to pass-down information and ease the process of future migrations, even if we do eventually move to full VMs.

## What's New in v1.2?

**6 Safety Features for Training Beginners:**

- **Operation Locking** - Prevents concurrent operations from corrupting data
- **Dry-Run First** - Shows plan before executing destructive operations  
- **Environment Validation** - Prevents mixing live/test
- **JSON Output** - Machine-readable inventory
- **Decision Trees** - Built-in guides (when to use --deep)
-  **Safety Docs** - Critical serialization warnings

**[Read Full v1.2 Update Summary →](UPDATE-SUMMARY-v1.2.md)**

---

## Quick Start

```bash
# Install
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate

# Run (interactive menu)
webdev-migrate

# Or use directly
webdev-migrate inventory portfolios.cs.earlham.edu
```

**[Complete Installation Guide →](QUICKSTART.md)**

---

## 📋 Features

| Operation | Safety | Description |
|-----------|--------|-------------|
| **inventory** | Safe | Show THE 8 FACTS + JSON output |
| **backup** | Locked | Create restorable backup |
| **restore** | Verified | Restore with 6-point checks |
| **migrate** | Careful | Cross-server migration |
| **clone-to-test** | Locked | Create testing environment |
| **promote-to-live** | Dry-run first | Deploy test to production |
| **healthcheck** | Safe | Comprehensive diagnostics |
| **url-audit --deep** | Safe | Find plugin URL issues |

**v1.2 Safety:**
- Operations locked (one at a time per site)
- Environment validated (can't mix live/test)
- Dry-run shown first (for destructive ops)
- Restore verified (6 automated checks)

---

## Documentation

### Getting Started
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute start
- **[TRAINING.md](TRAINING.md)** - Complete beginner's guide

### Reference
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[IMPLEMENTATION.md](IMPLEMENTATION.md)** - Technical details  
- **[WALKTHROUGHS.md](WALKTHROUGHS.md)** - Step-by-step examples

### Updates
- **[UPDATE-SUMMARY-v1.2.md](UPDATE-SUMMARY-v1.2.md)** - What's new in v1.2
- **[UPDATE-SUMMARY-v1.1.md](UPDATE-SUMMARY-v1.1.md)** - What changed in v1.1

### Version Archives
- **[versions/v1.0/](versions/v1.0/)** - v1.0 documentation
- **[versions/v1.1/](versions/v1.1/)** - v1.1 documentation

---

## Common Commands

### Daily Operations
```bash
# Check a site (THE 8 FACTS)
webdev-migrate inventory portfolios.cs.earlham.edu

# Health check
webdev-migrate healthcheck portfolios.cs.earlham.edu

# Backup
webdev-migrate backup /var/www/wordpress-site site live
```

### Migration
```bash
# Dry-run first (ALWAYS)
webdev-migrate --dry-run migrate web:site web-urey:site

# Execute
webdev-migrate migrate web:site web-urey:site
```

### URL Issues
```bash
# Standard scan
webdev-migrate url-audit /var/www/site

# Deep scan (for plugin metadata - DFlip, galleries, etc.)
webdev-migrate url-audit --deep /var/www/site
```

---

## THE 8 FACTS

Every inventory shows:

1. **DOMAIN** - What domain?
2. **SERVER** - Which machine?
3. **WORDPRESS PATH** - Where are files?
4. **DATABASE** - Name, user, host
5. **ENVIRONMENT** - Live or test?
6. **MULTISITE CONTEXT** - Blog ID? Table prefix?
7. **UPLOADS CONFIG** - Path, URL, sites/<id>?
8. **THEME & PLUGINS** - Active theme, plugin count

*Standardized format builds training muscle memory.*

---

## Version History

| Version | Date | Lines | Key Features |
|---------|------|-------|--------------|
| **1.2.0** | Feb 13, 2025 | 3,420 | Safety (locking, validation) |
| 1.1.0 | December 1, 2025 | 3,007 | Production hardening |
| 1.0.0 | October 3, 2025 | 2,340 | Initial unified tool |

**[Complete Changelog →](CHANGELOG.md)**

---

## Upgrade from v1.1

Drop-in replacement:

```bash
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate
```

No config changes needed. New safety features work immediately.

---

## Configuration

Optional `~/.webdev-migrate.conf`:

```bash
SOURCE_HOST="web"
DEST_HOST="web-urey"
SSH_USER="root"
WEBROOT="/var/www"
BACKUP_ROOT="/srv/backups/wp"
```

**[Full Config Example →](webdev-migrate.conf.example)**

---

## Troubleshooting

### "Another operation is already running"
```bash
# Check lock
ls /var/lock/webdev-migrate/

# If stuck, remove
sudo rm /var/lock/webdev-migrate/SITE.lock
```

### "Environment mismatch"
```bash
# Fix: Point at correct path
# For test: /var/www/wordpress-testing-SITE
# For live: /var/www/wordpress-SITE
```

### Plugin URLs broken after migration
```bash
# Use deep scan
webdev-migrate url-audit --deep /var/www/site
```

**[Complete Troubleshooting →](TRAINING.md#part-7-what-can-go-wrong)**

---

## Support

- **Tool questions:** njalshe23@earlham.edu (Nour)
- **Infrastructure:** Porter (sysadmin) / Charlie (webdev)
- **Logs:** `/var/log/webdev-migrate/`

```bash
# Check logs
ls -lt /var/log/webdev-migrate/
tail -100 /var/log/webdev-migrate/LATEST.log
```

---

## Credits

- **Developer:** Nour Al-Sheikh
- **AI Assistant:** I lost count. Consider this my disclosure. :)
- **Testing:** EC Webdev.
- **v1.1 Driver:** earlhamword.com DFlip debugging.
- **v1.2 Design:** Production personal experience.

---

## Quick Reference

```bash
# Safety first
--dry-run                      # Always safe

# Core operations
inventory DOMAIN               # Check site
backup PATH SLUG ENV           # Backup
restore BACKUP PATH            # Restore
migrate SRC DST                # Move
clone-to-test SLUG             # Test copy
promote-to-live SLUG           # Deploy

# URL issues
url-audit PATH                 # Standard
url-audit --deep PATH          # Plugin scan

# Help
--help                         # Full help
(no args)                      # Interactive menu
```

---

**For complete documentation, see the individual `.md` files.**

**Questions? Check [TRAINING.md](TRAINING.md) or [WALKTHROUGHS.md](WALKTHROUGHS.md)**
