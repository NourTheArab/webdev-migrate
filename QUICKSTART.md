# Quick Start Guide

**Get up and running in 5 minutes**

---

## Installation (30 seconds)

```bash
# Copy to system
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate

# Verify
webdev-migrate --version
# Should show: Version 1.3.0
```

**That's it.** No dependencies, no configuration needed.

---

## Your First Commands (3 minutes)

### 1. Check a Site (Safe)

```bash
webdev-migrate inventory portfolios.cs.earlham.edu
```

**What you'll see: THE 8 FACTS**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
THE 8 FACTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DOMAIN
   portfolios.cs.earlham.edu

2. SERVER
   web-urey (192.168.1.20)

3. WORDPRESS PATH
   /var/www/wordpress-portfolios

4. DATABASE
   Name: wp_portfolios
   User: wpuser
   Host: localhost

5. ENVIRONMENT
   LIVE (production site)

6. MULTISITE CONTEXT
   Standalone WordPress installation

7. UPLOADS CONFIGURATION
   Path: /var/www/wordpress-portfolios/wp-content/uploads
   URL: https://portfolios.cs.earlham.edu/wp-content/uploads

8. THEME & PLUGINS
   Active Theme: Divi
   Plugins: 23 active, 4 inactive
```

**Why this matters:** These 8 facts tell you everything you need to know before working on a site.

### 2. List All Sites (Safe)

```bash
sudo webdev-migrate list-all-sites
```

**Example of what you'll see:**
```
Found 5 WordPress installations on this server:

🟢 portfolios.cs.earlham.edu                    [STANDALONE]
   /var/www/wordpress-portfolios | 1.3GB | LIVE

🟢 fieldscience.cs.earlham.edu                  [STANDALONE]
   /var/www/wordpress-fieldscience | 5.5GB | LIVE

🟡 earlhamword.testing.cs.earlham.edu           [MULTISITE]
   /var/www/wordpress-testing-earlhamword | 2.4GB | TEST
```

### 3. Create a Backup (Safe)

```bash
sudo webdev-migrate backup /var/www/wordpress-portfolios portfolios live
```

**What happens:**
1. Shows size estimate (~1.3GB)
2. Creates timestamped backup
3. Verifies backup worked
4. Shows backup location
5. Cleans up old backups (>30 days)

**Backup saved to:**
```
/srv/backups/wp/portfolios/live/20260214-143000/
├── db.sql.gz         (database dump)
├── files.tar.gz      (WordPress files)
└── manifest.txt      (backup info)
```

### 4. Run Health Check (Safe)

```bash
sudo webdev-migrate healthcheck portfolios.cs.earlham.edu
```

**What it checks:**
- ✓ WordPress files present
- ✓ Database connection works
- ✓ URLs configured correctly
- ✓ Apache serving the site
- ✓ File permissions correct
- ✓ Site accessible (HTTP 200)
- ✓ Error log check

---

## Interactive Mode (Easiest for Beginners)

**Just type:**
```bash
webdev-migrate
```

**You'll see a menu:**
```
╔══════════════════════════════════════════════════════════════════╗
║         ╦ ╦╔═╗       WEBDEV MIGRATION TOOL                      ║
║         ║║║╠═╝       Version 1.3.0                              ║
╚══════════════════════════════════════════════════════════════════╝

SCOPE SELECTION:

  L) Local Server Operations
     Work on THIS server only

  M) Multi-Server Mode
     Manage multiple servers, cross-server migrations

  S) List sites (local server)
  R) Quick Reference

  0) Exit

Choice:
```

**Choose what you want to do.** The tool guides you through each operation.

---

## Multi-Server Mode (New in v1.3!)

### Add a Remote Server

```bash
sudo webdev-migrate add-server web 192.168.1.10 njalshe23 --proxy jumphost.cs.earlham.edu
```

**What happens:**
1. Tests connection
2. Checks for WordPress sites
3. Saves as profile
4. Ready to use

### Migrate Between Servers

```bash
# Interactive (recommended for first time)
sudo webdev-migrate multi-server
# Choose: 2) Migrate site (server → server)

# Or direct command (for pros)
sudo webdev-migrate migrate web:portfolios web-urey:portfolios
```

**The wizard walks you through:**
1. Select source server + site
2. Select destination
3. Pre-migration validation (WordPress responding, database healthy, disk space)
4. Safety confirmation (type MIGRATE)
5. Optional rollback backup
6. Execute migration

**[Full Multi-Server Guide →](docs/MULTI-SERVER.md)**

---

## Next Steps

### Learn More
- **[TRAINING.md](docs/TRAINING.md)** — Complete 1-hour tutorial
- **[WALKTHROUGHS.md](docs/WALKTHROUGHS.md)** — Step-by-step examples
- **[PHILOSOPHY.md](docs/PHILOSOPHY.md)** — Why the tool works this way

### Reference
- **[Full Command List](#)** — All available commands
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — Fix common issues
- **[IMPLEMENTATION.md](docs/IMPLEMENTATION.md)** — Technical details

---

## Common Tasks Cheat Sheet

### Daily Operations
```bash
# Check a site
webdev-migrate inventory DOMAIN

# Backup a site
sudo webdev-migrate backup PATH SLUG ENV

# Health check
sudo webdev-migrate healthcheck DOMAIN
```

### Migrations
```bash
# Clone to test
sudo webdev-migrate clone-to-test SLUG

# Promote test → live
sudo webdev-migrate promote-to-live SLUG

# Cross-server migration
sudo webdev-migrate multi-server
```

### URL Issues
```bash
# Standard scan
sudo webdev-migrate url-audit PATH

# Deep scan (for plugins like DFlip)
sudo webdev-migrate url-audit --deep PATH
```

### Multi-Server
```bash
# Add server
sudo webdev-migrate add-server NAME IP USER --proxy JUMP

# Test connection
sudo webdev-migrate test-connection NAME

# List saved servers
webdev-migrate server-profiles
```

---

## Optional Configuration

**Create:** `~/.webdev-migrate.conf`

```bash
# Backup retention
BACKUP_RETENTION_DAYS=30  # Clean backups older than this

# Server defaults (optional)
SOURCE_HOST="web"
DEST_HOST="web-urey"
SSH_USER="njalshe23"

# Paths (if different from defaults)
WEBROOT="/var/www"
BACKUP_ROOT="/srv/backups/wp"
```

**This is optional.** Tool works fine without it.

---

## Help

### Getting Help
```bash
# Show all commands
webdev-migrate --help

# Quick reference
webdev-migrate quick-reference

# Check version
webdev-migrate --version
```

### Logs
```bash
# View recent logs
tail -100 /var/log/webdev-migrate/webdev-migrate-LATEST.log

# Check for errors
grep ERROR /var/log/webdev-migrate/*.log
```

### Support
- **Documentation:** See [README.md](README.md) for full docs
- **Troubleshooting:** See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Questions:** njalshe23@earlham.edu/@NourTheArab

---

## Safety Features

**The tool protects you from mistakes:**

- **Operation Locking** — One operation per site at a time
- **Dry-Run First** — See what will happen before it happens
- **Environment Validation** — Can't mix live/test
- **Confirmation Strings** — Type "MIGRATE" to confirm dangerous ops
- **Automatic Backups** — Creates rollback points
- **Size Warnings** — Warns before large operations
- **Auto-Cleanup** — Prevents disk from filling up

---

## What to Learn Next

**If you're new:**
1. Do Quick Start (you're here!)
2. → Read [TRAINING.md](docs/TRAINING.md) — Complete beginner's guide
3. → Try [WALKTHROUGHS.md](docs/WALKTHROUGHS.md) — Real examples

**If you want multi-server:**
1. Do Quick Start
2. → Read [MULTI-SERVER.md](docs/MULTI-SERVER.md) — Cross-server guide
3. → Set up SSH keys for smoother operation

**If something broke:**
1. → Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. → Check logs in `/var/log/webdev-migrate/`
3. → Email njalshe23@earlham.edu with logs

---

**Ready to become a pro? Continue to [TRAINING.md](docs/TRAINING.md) →**
