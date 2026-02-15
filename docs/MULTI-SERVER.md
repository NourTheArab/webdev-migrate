# Multi-Server Migration Guide

**How to work across multiple WordPress servers**

*New in v1.3.0*

---

## What is Multi-Server Mode?

**Before v1.3:** All operations on the local server only.

**v1.3:** Manage multiple servers in one session, migrate between them.

**Example workflow:**
1. List sites on both web and web-urey
2. Migrate portfolios from web → web-urey
3. Verify migration with health check
4. All from one terminal session

---

## Quick Start

```bash
# Enter multi-server mode
sudo webdev-migrate multi-server

# Follow the wizard:
# 1. Add servers to session
# 2. Choose operation (migrate, list sites, etc.)
# 3. Follow prompts
```

**That's the easiest way.** The wizard handles everything.

---

## Understanding Server Sessions

### What is a Session?

A **session** is a temporary workspace where you add servers and perform operations.

```
Session (lasts until you exit multi-server mode):
├── localhost (always present)
├── web (192.168.1.10, added by you)
└── web-urey (192.168.1.20, added by you)
```

### What are Server Profiles?

**Profiles** are saved server configurations stored in:
```
~/.webdev-migrate/servers/web.conf
~/.webdev-migrate/servers/web-urey.conf
```

**Why save profiles?**
- Type connection details once
- Reuse across sessions
- Share with team (optional)

---

## Step-by-Step: First Cross-Server Migration

### Step 1: Add Your First Server

**Option A: Interactive (Recommended)**

```bash
sudo webdev-migrate multi-server
# Choose: A) Add server to session
```

The wizard will ask:
1. **Server name:** Short name (e.g., "web")
2. **IP address:** 192.168.1.10 (run `hostname -I` on that server to find it)
3. **SSH username:** Usually your username (e.g., njalshe23)
4. **ProxyJump needed?** y/n (Most Earlham servers: YES, use jumphost.cs.earlham.edu)
5. **Save as profile?** y/n (YES - saves typing next time)

**Option B: Command Line (For Pros)**

```bash
sudo webdev-migrate add-server web 192.168.1.10 njalshe23 --proxy jumphost.cs.earlham.edu
```

### Step 2: Test the Connection

**Before trusting a server, test it:**

```bash
sudo webdev-migrate test-connection web
```

**What it checks:**
1. ✓ Host reachability (ping or TCP port 22)
2. ✓ SSH connection (with ProxyJump if configured)
3. ✓ Sudo access (passwordless or password)
4. ✓ WP-CLI available
5. ✓ WordPress sites found

**If all pass:** Server is ready.

**If any fail:** Error message explains what to fix.

### Step 3: List Sites Across Servers

```bash
sudo webdev-migrate multi-server
# Choose: 1) View all sites across all servers
```

**Output example:**
```
┌─ localhost (web-urey) ─────────────────────────────────────────┐

  🟢 portfolios.cs.earlham.edu                    [STANDALONE]
     /var/www/wordpress-portfolios | 1.3GB | live

  🟢 fieldscience.cs.earlham.edu                  [STANDALONE]
     /var/www/wordpress-fieldscience | 5.5GB | live

└─────────────────────────────────────────────────────────────────┘

┌─ web (192.168.1.10) ───────────────────────────────────────────┐

  🟢 academics.cs.earlham.edu                     [STANDALONE]
     /var/www/wordpress-academics | 2.1GB | live

  🟡 earlhamword.com                              [MULTISITE]
     /var/www/wordpress-earlhamword | 8.3GB | live

└─────────────────────────────────────────────────────────────────┘

Summary:
  Total across all servers: 4 sites
```

### Step 4: Migrate a Site

```bash
sudo webdev-migrate multi-server
# Choose: 2) Migrate site (server → server)
```

**The wizard walks you through 6 steps:**

#### Step 1: Select Source
```
Available sites:
  [localhost]
    1. portfolios.cs.earlham.edu
    2. fieldscience.cs.earlham.edu
  
  [web]
    3. academics.cs.earlham.edu
    4. earlhamword.com

Select source (number): 3
```

#### Step 2: Select Destination
```
Available servers (excluding source):
  1) localhost

Select destination server: 1

Domain for migrated site [academics.cs.earlham.edu]: 
Environment (live/test) [live]: 
```

#### Step 3: Pre-Migration Validation
```
[web] Validating source...
  ✓ WordPress responding
  ✓ Database healthy

[localhost] Validating destination...
  ✓ Destination writable
  ✓ Sufficient disk space (50GB available)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  VALIDATION PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Step 4: Migration Plan
```
This will:
  1. Create backup on web
  2. Transfer backup: web → localhost
  3. Restore on localhost
  4. Update URLs and configuration
  5. Configure Apache

Source: web:academics.cs.earlham.edu
Destination: localhost:academics.cs.earlham.edu
Size: 2.1GB
```

#### Step 5: Safety Confirmation
```
Type MIGRATE to confirm: MIGRATE

Create rollback backup of destination before migration? (Y/n): y
```

#### Step 6: Execute
```
[web] Creating backup...
  ✓ Database dumped (45MB)
  ✓ Files archived (2.0GB)

[Transfer] web → localhost...
  Progress: [████████████████████] 100% | 2.1GB @ 45MB/s
  ✓ Transfer complete (45 seconds)

[localhost] Restoring...
  ✓ Database imported
  ✓ Files extracted
  ✓ URLs updated
  ✓ Permissions set

YIPPIE!! MIGRATION COMPLETE!
```

---

## Advanced Topics

### Working with ProxyJump

**What is ProxyJump?**

A way to SSH through an intermediate server:

```
You → jumphost.cs.earlham.edu → web (192.168.1.10)
```

**Why Earlham needs it:** Internal servers (like web-urey) aren't directly accessible from off-campus.

**How the tool handles it:**

When you save a server profile with a proxy:
```bash
# Server profile: web
SERVER_PROXY="jumphost.cs.earlham.edu"
```

All SSH commands automatically become:
```bash
ssh -J jumphost.cs.earlham.edu njalshe23@192.168.1.10 "command"
```

**You don't need to think about it.** The tool handles routing.

---

### SSH Key Setup (Recommended)

**Password-based SSH works but is slow** (you'll type your password repeatedly).

**Better: SSH keys**

```bash
# On your laptop/machine
ssh-keygen -t rsa -b 4096

# Copy to jumphost
ssh-copy-id your-username@jumphost.cs.earlham.edu

# Copy to internal servers (through jumphost)
ssh-copy-id -J jumphost.cs.earlham.edu your-username@192.168.1.10
ssh-copy-id -J jumphost.cs.earlham.edu your-username@192.168.1.20
```

**After this:** No more passwords. Tool runs smoothly.

---

### Server Profile Management

**List all saved profiles:**
```bash
webdev-migrate server-profiles
```

**Example output:**
```
Saved server profiles:

  • web
    IP: 192.168.1.10
    Proxy: jumphost.cs.earlham.edu
    Last tested: 2026-02-14 10:30:00

  • web-urey
    IP: 192.168.1.20
    Proxy: jumphost.cs.earlham.edu
    Last tested: 2026-02-14 10:35:00
```

**Edit a profile manually:**
```bash
nano ~/.webdev-migrate/servers/web.conf
```

**Delete a profile:**
```bash
rm ~/.webdev-migrate/servers/web.conf
```

---

### Transfer Performance

**Transfers go through localhost:**

```
web → localhost (temp directory) → web-urey
```

**Why not direct server-to-server?**

1. Security: Don't want web → web-urey SSH keys
2. Monitoring: You see the progress
3. Debugging: If transfer fails, files are on your machine

**Future improvement (v1.4?):** Direct transfers with progress tunneling.

---

## Common Workflows

### Workflow 1: Regular Site Refresh

**Scenario:** Update test site from live periodically.

```bash
# Step 1: Add servers (once)
webdev-migrate add-server web 192.168.1.10 njalshe23 --proxy jumphost

# Step 2: Migrate (whenever you need)
webdev-migrate multi-server
# Choose: 2) Migrate site
# Select: web:portfolios.live → localhost:portfolios.test
```

**Make it a script:**
```bash
#!/bin/bash
# refresh-test-site.sh

webdev-migrate multi-server << EOF
2
1
1
portfolios.test
test
MIGRATE
y
EOF
```

(See [examples/migration-workflow.sh](../examples/migration-workflow.sh))

---

### Workflow 2: Decommission Old Server

**Scenario:** Moving all sites from web → web-urey.

```bash
# Step 1: List sites on old server
webdev-migrate multi-server
# Choose: 1) View all sites
# Note which sites are on web

# Step 2: Migrate each site
# (repeat for each site)
webdev-migrate multi-server
# Choose: 2) Migrate site
# Select: web:site → web-urey:site

# Step 3: Verify
# Check each site works on web-urey
# Run health checks

# Step 4: Update DNS
# (outside this tool)

# Step 5: Decommission web
# (after confirming everything works)
```

---

### Workflow 3: Emergency Rollback

**Scenario:** Migration went wrong, need to undo.

```bash
# If you created a rollback backup:
sudo webdev-migrate restore /srv/backups/wp/SITE-rollback/pre-migration/TIMESTAMP /var/www/wordpress-SITE

# The tool told you this path after migration:
# "To rollback: restore from /srv/backups/wp/..."
```

---

## Troubleshooting

### Error: "Server not in session"

**Problem:** Trying to use a server you haven't added.

**Solution:**
```bash
# Check active servers
webdev-migrate multi-server
# Choose: 7) Manage server connections
# Add the server
```

---

### Error: "SSH connection failed"

**Problem:** Can't connect to server.

**Solutions:**

1. **Check if server is reachable:**
   ```bash
   ping 192.168.1.10
   # or
   telnet 192.168.1.10 22
   ```

2. **Check SSH keys:**
   ```bash
   ssh -J jumphost.cs.earlham.edu your-username@192.168.1.10
   # Should connect without password
   ```

3. **Check ProxyJump:**
   ```bash
   ssh your-username@jumphost.cs.earlham.edu
   # Should work
   ```

4. **Test connection with tool:**
   ```bash
   webdev-migrate test-connection web
   # Shows detailed diagnostics
   ```

---

### Error: "Destination path already exists"

**Problem:** Site already exists on destination.

**Solution:**

**Option 1:** Overwrite (the tool asks)
```
Destination path already exists: /var/www/wordpress-site
  Overwrite? (y/N): y
```

**Option 2:** Choose different path
```
Destination path already exists: /var/www/wordpress-site
  Overwrite? (y/N): n
Migration cancelled
```

Then migrate with different domain/path.

---

### Error: "Insufficient disk space"

**Problem:** Destination doesn't have enough space.

**Check space:**
```bash
df -h /var/www
```

**Solutions:**

1. **Clean up old backups:**
   ```bash
   # Check backup sizes
   du -sh /srv/backups/wp/*
   
   # Remove old backups manually
   rm -rf /srv/backups/wp/old-site
   ```

2. **Increase retention cleanup:**
   ```bash
   # Edit config
   nano ~/.webdev-migrate.conf
   
   # Change retention
   BACKUP_RETENTION_DAYS=15  # instead of 30
   ```

---

### Error: "Transfer failed"

**Problem:** Network issue during transfer.

**Solutions:**

1. **Retry:** Transfers are resumable in most cases

2. **Check network:**
   ```bash
   # Test transfer speed
   scp -J jumphost test-file user@192.168.1.10:/tmp/
   ```

3. **Use compression:**
   ```bash
   # Already enabled by default (rsync -z)
   # But you can check in logs
   tail /var/log/webdev-migrate/latest.log
   ```

---

## Reference

### All Multi-Server Commands

```bash
# Interactive mode
webdev-migrate multi-server

# Server management
webdev-migrate add-server NAME IP USER [--proxy HOST]
webdev-migrate test-connection NAME
webdev-migrate server-profiles

# Direct operations (advanced)
webdev-migrate migrate SOURCE:SITE DEST:SITE
```

### Server Profile File Format

```bash
# ~/.webdev-migrate/servers/web.conf

SERVER_NAME="web"
SERVER_IP="192.168.1.10"
SERVER_USER="njalshe23"
SERVER_PROXY="jumphost.cs.earlham.edu"
SERVER_PROXY_USER="njalshe23"
SERVER_DESCRIPTION="Production server (old)"

SSH_KEY_PATH="${HOME}/.ssh/id_rsa"

LAST_TEST_DATE="2026-02-14 10:30:00"
LAST_TEST_STATUS="success"
SITES_FOUND="8"
```

### Connection Test Results

```bash
Testing Connection to: web

  ✓ Host reachable (ping)
  ✓ SSH connection successful
  ✓ Passwordless sudo available
  ✓ WP-CLI available: WP-CLI 2.10.0
  ✓ Found 8 WordPress sites

Connection Test Summary:
  Passed: 5
  Failed: 0

Server 'web' ready for operations
```

---

## 🎯 Best Practices

### 1. Always Test Connections First

Before migrating, test both servers:
```bash
webdev-migrate test-connection web
webdev-migrate test-connection web-urey
```

### 2. Use Server Profiles

Save time by storing connection details:
```bash
# Save once
webdev-migrate add-server web 192.168.1.10 njalshe23 --proxy jumphost

# Use forever
# (loads automatically in multi-server mode)
```

### 3. Create Rollback Backups

Always say "yes" when asked:
```
Create rollback backup before migration? (Y/n): y
```

One backup saves hours of pain.

### 4. Verify After Migration

```bash
# Run health check
webdev-migrate healthcheck DOMAIN

# Check URLs
webdev-migrate url-audit --deep /path
```

### 5. Keep Logs

```bash
# Logs are in
/var/log/webdev-migrate/

# Check after migration
tail -100 /var/log/webdev-migrate/webdev-migrate-LATEST.log
```

---

## Tips & Tricks

### Tip 1: Batch Migrations

Migrating multiple sites? Write a script:

```bash
#!/bin/bash
# See examples/migration-workflow.sh

SITES=("portfolios" "academics" "fieldscience")

for site in "${SITES[@]}"; do
    echo "Migrating $site..."
    webdev-migrate migrate web:$site web-urey:$site
done
```

### Tip 2: Connection Pooling

The tool reuses SSH connections (ControlMaster).

**What this means:** First connection is slow (3-5 seconds), subsequent connections are instant (<0.5 seconds).

**Result:** Multi-site migrations are much faster.

### Tip 3: Parallel Testing

Test multiple servers at once:

```bash
# Terminal 1
webdev-migrate test-connection web

# Terminal 2
webdev-migrate test-connection web-urey

# Terminal 3
webdev-migrate test-connection backup-server
```

All run in parallel. Faster than sequential.

---

## Future Features (Planned)

- **Direct server-to-server transfers** (skip localhost intermediate)
- **Migration templates** (save common workflows)
- **Site comparison** (diff between same site on different servers)
- **Automated DNS switching** (after successful migration)

---

**Questions? Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or open an issue.**
