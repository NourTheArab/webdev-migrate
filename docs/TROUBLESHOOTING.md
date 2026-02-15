# Troubleshooting Guide

**Common problems and how to fix them**

---

## General Debugging

**Before opening an issue, check:**

### 1. Read the Error Message

The tool explains what went wrong:
```
✗ Database connection failed

Common causes:
  • Wrong credentials in wp-config.php
  • MySQL service not running (check: systemctl status mysql)
  • Database doesn't exist
```

**These hints usually solve 80% of problems.**

### 2. Check the Logs

```bash
# View recent logs
ls -lt /var/log/webdev-migrate/

# Read latest
tail -100 /var/log/webdev-migrate/webdev-migrate-LATEST.log

# Search for errors
grep ERROR /var/log/webdev-migrate/webdev-migrate-LATEST.log
```

### 3. Test Components Individually

```bash
# Can you connect to MySQL?
mysql -u wpuser -p wp_database

# Can you SSH to the server?
ssh user@server

# Is WP-CLI working?
wp --version

# Can you write to the directory?
touch /var/www/test.txt && rm /var/www/test.txt
```

---

## Common Issues

### Issue #1: "Another operation is already running"

**Error message:**
```
✗ Another operation is already running for this site
Lock file: /var/lock/webdev-migrate/portfolios.lock
Process: 12345 (started 10 minutes ago)
```

**Cause:** Previous operation didn't clean up its lock.

**Solutions:**

**If the operation is actually running:**
```bash
# Check if process exists
ps aux | grep 12345

# Wait for it to finish
```

**If the operation crashed/was killed:**
```bash
# Remove stale lock
sudo rm /var/lock/webdev-migrate/portfolios.lock

# Try again
webdev-migrate backup ...
```

**If this happens often:**
```bash
# Clean all stale locks
sudo find /var/lock/webdev-migrate -name "*.lock" -mmin +60 -delete

# This removes locks older than 60 minutes
```

---

### Issue #2: Database Connection Failed

**Error variants:**
- "Access denied for user"
- "Unknown database"
- "Can't connect to MySQL server"

**Solutions:**

#### 2a. Check Credentials
```bash
# View wp-config.php
cat /var/www/wordpress-site/wp-config.php | grep DB_

# Should show:
# define('DB_NAME', 'wp_database');
# define('DB_USER', 'wpuser');
# define('DB_PASSWORD', 'password');
# define('DB_HOST', 'localhost');
```

#### 2b. Test MySQL Connection
```bash
# Try manually
mysql -h localhost -u wpuser -p wp_database

# If this fails, credentials are wrong
```

#### 2c. Check MySQL is Running
```bash
sudo systemctl status mysql

# If not running:
sudo systemctl start mysql
```

#### 2d. Create Database if Missing
```bash
# Login as root
sudo mysql

# Create database
CREATE DATABASE wp_database;
GRANT ALL ON wp_database.* TO 'wpuser'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

---

### Issue #3: "Environment mismatch" or "Wrong environment"

**Error:**
```
✗ Environment mismatch detected
Expected: live
Found: test
```

**Cause:** Pointing at wrong directory.

**Solution:**

Check your paths:
```bash
# Test sites should be in
/var/www/wordpress-testing-SITE

# Live sites should be in
/var/www/wordpress-SITE

# Use the correct path
webdev-migrate inventory /var/www/wordpress-testing-SITE  # for test
webdev-migrate inventory /var/www/wordpress-SITE          # for live
```

---

### Issue #4: URLs Still Wrong After Migration

**Symptoms:**
- Images don't load
- Links go to old domain
- Plugin settings broken

**Solutions:**

#### 4a. Standard URL Fix
```bash
# Run search-replace
webdev-migrate url-audit /var/www/site
```

#### 4b. Deep Scan (For Plugin Issues)
```bash
# Scan plugin metadata
webdev-migrate url-audit --deep /var/www/site
```

#### 4c. Manual Check
```bash
# Search database directly
sudo -u www-data wp --path=/var/www/site search-replace "old.com" "new.com" --dry-run

# If dry-run looks good:
sudo -u www-data wp --path=/var/www/site search-replace "old.com" "new.com"
```

#### 4d. Check Multisite URLs
```bash
# For multisite, also check network options
sudo -u www-data wp --path=/var/www/site option get siteurl
sudo -u www-data wp --path=/var/www/site option get home

# Update if wrong
sudo -u www-data wp --path=/var/www/site option update siteurl "https://correct.url"
```

---

### Issue #5: Backup Failed / Backup File Empty

**Error:**
```
✗ Backup file is missing or empty: /srv/backups/wp/.../db.sql.gz
```

**Solutions:**

#### 5a. Check Disk Space
```bash
df -h /srv/backups

# If <5GB free:
# Clean old backups
du -sh /srv/backups/wp/*
sudo rm -rf /srv/backups/wp/old-site
```

#### 5b. Check Database Credentials
```bash
# The backup uses credentials from wp-config.php
# Test them:
cd /var/www/wordpress-site
cat wp-config.php | grep DB_

# Test connection
mysql -u USER -p DATABASE
```

#### 5c. Check mysqldump
```bash
# Try manual backup
mysqldump -u wpuser -p wp_database > test.sql

# If this fails, check MySQL permissions
```

#### 5d. Check Permissions
```bash
# Backup directory must be writable
ls -ld /srv/backups/wp

# Should show: drwxr-xr-x root root
# If wrong:
sudo chmod 755 /srv/backups/wp
```

---

### Issue #6: Restore Failed

**Error variants:**
- "SQL syntax error"
- "Table already exists"
- "Import failed"

**Solutions:**

#### 6a. Database Already Exists
```bash
# Drop existing database
sudo mysql -e "DROP DATABASE wp_database;"

# Recreate
sudo mysql -e "CREATE DATABASE wp_database;"

# Try restore again
```

#### 6b. Check Backup Integrity
```bash
# Verify backup file
gunzip -t /srv/backups/wp/.../db.sql.gz

# If corrupted, restore from earlier backup
```

#### 6c. Manual Restore
```bash
# Try manually
gunzip -c /srv/backups/wp/.../db.sql.gz | mysql -u wpuser -p wp_database

# If this shows errors, check:
# - SQL file for corruption
# - MySQL version compatibility
```

---

### Issue #7: SSH / Multi-Server Connection Issues

**Error variants:**
- "SSH connection failed"
- "Server not in session"
- "Permission denied (publickey)"

**Solutions:**

#### 7a. Test SSH Manually
```bash
# Direct connection
ssh user@192.168.1.10

# With ProxyJump
ssh -J jumphost.cs.earlham.edu user@192.168.1.10

# If these don't work, fix SSH first
```

#### 7b. Setup SSH Keys
```bash
# Generate key (if you don't have one)
ssh-keygen -t rsa -b 4096

# Copy to server
ssh-copy-id user@server

# Or with ProxyJump
ssh-copy-id -J jumphost.cs.earlham.edu user@server
```

#### 7c. Test Connection
```bash
# Use tool's connection test
webdev-migrate test-connection web

# This shows exactly what's wrong:
# - Host unreachable
# - SSH failed
# - Sudo not available
# - WP-CLI missing
```

#### 7d. Check ProxyJump Config
```bash
# View server profile
cat ~/.webdev-migrate/servers/web.conf

# Should have:
SERVER_PROXY="jumphost.cs.earlham.edu"

# If missing, re-add server with --proxy flag
```

---

### Issue #8: "Permission denied" Errors

**Error:**
```
✗ Permission denied: /var/www/wordpress-site
```

**Solutions:**

#### 8a. Run with Sudo
```bash
# Most operations need sudo
sudo webdev-migrate backup /var/www/site ...
```

#### 8b. Check File Ownership
```bash
# WordPress files should be www-data
ls -l /var/www/wordpress-site

# Fix ownership
sudo chown -R www-data:www-data /var/www/wordpress-site
```

#### 8c. Check Directory Permissions
```bash
# Files: 644, Directories: 755
sudo find /var/www/wordpress-site -type f -exec chmod 644 {} \;
sudo find /var/www/wordpress-site -type d -exec chmod 755 {} \;

# wp-config.php: 600
sudo chmod 600 /var/www/wordpress-site/wp-config.php
```

---

### Issue #9: Plugin-Specific Breakage

#### DFlip Plugin URLs

**Symptom:** Flipbooks don't load after migration.

**Cause:** Serialized URLs in postmeta.

**Solution:**
```bash
# Use deep scan
webdev-migrate url-audit --deep /var/www/site

# This finds serialized URLs standard search-replace misses
```

#### Gallery / Media Issues

**Symptom:** Gallery images broken after migration.

**Cause:** Hardcoded URLs in gallery settings.

**Solution:**
```bash
# Deep scan
webdev-migrate url-audit --deep /var/www/site

# Check uploads path
wp option get upload_path
wp option get upload_url_path

# Update if wrong
wp option update upload_url_path "https://new.site/wp-content/uploads"
```

---

### Issue #10: Multisite-Specific Problems

#### Wrong Blog ID

**Symptom:** Can't find subsite.

**Solution:**
```bash
# List all subsites
wp site list

# Check specific blog_id
wp --url=https://subsite.network.com option get siteurl
```

#### Table Prefix Issues

**Symptom:** "Table not found" errors.

**Solution:**
```bash
# Check table prefix in wp-config.php
grep table_prefix /var/www/wordpress-network/wp-config.php

# Check actual tables
mysql -u wpuser -p wp_network -e "SHOW TABLES LIKE 'wp_%';"

# For blog_id=2, tables should be wp_2_posts, wp_2_options, etc.
```

---

## 🔧 Advanced Troubleshooting

### Enable Debug Mode

**Add to wp-config.php:**
```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
```

**Check debug log:**
```bash
tail -f /var/www/wordpress-site/wp-content/debug.log
```

### Check Apache Logs

```bash
# Error log
sudo tail -f /var/log/apache2/error.log

# Access log
sudo tail -f /var/log/apache2/access.log

# Site-specific log (if configured)
sudo tail -f /var/log/apache2/site-error.log
```

### Test WordPress from Command Line

```bash
# Check if WordPress is healthy
sudo -u www-data wp --path=/var/www/site core verify-checksums

# Check database
sudo -u www-data wp --path=/var/www/site db check

# Check plugins
sudo -u www-data wp --path=/var/www/site plugin list
```

### Verify Apache Configuration

```bash
# Test config syntax
sudo apache2ctl configtest

# Should show: Syntax OK

# Reload Apache
sudo systemctl reload apache2
```

---

## Diagnostic Checklist

**When nothing works, go through this:**

- [ ] Check logs: `/var/log/webdev-migrate/webdev-migrate-LATEST.log`
- [ ] Test MySQL: `mysql -u wpuser -p wp_database`
- [ ] Test WP-CLI: `wp --version`
- [ ] Check disk space: `df -h /var/www`
- [ ] Check permissions: `ls -la /var/www/wordpress-site`
- [ ] Test Apache: `sudo apache2ctl configtest`
- [ ] Check running processes: `ps aux | grep webdev-migrate`
- [ ] Remove stale locks: `sudo rm /var/lock/webdev-migrate/*.lock`
- [ ] Test SSH (for multi-server): `ssh user@server`
- [ ] Check DNS: `ping site.domain.com`

---

## Still Stuck?

### Collect Debug Info

```bash
# Generate debug report
echo "=== System Info ===" > debug-report.txt
uname -a >> debug-report.txt
echo "" >> debug-report.txt

echo "=== Disk Space ===" >> debug-report.txt
df -h >> debug-report.txt
echo "" >> debug-report.txt

echo "=== MySQL Status ===" >> debug-report.txt
sudo systemctl status mysql >> debug-report.txt
echo "" >> debug-report.txt

echo "=== Recent Logs ===" >> debug-report.txt
tail -100 /var/log/webdev-migrate/webdev-migrate-LATEST.log >> debug-report.txt
echo "" >> debug-report.txt

echo "=== WP-CLI Version ===" >> debug-report.txt
wp --version >> debug-report.txt

# Send this file when asking for help
```

### Contact Info

- **Tool questions:** njalshe23@earlham.edu (Nour)
- **Infrastructure:** Porter (sysadmin) / Charlie (webdev)
- **GitLab issues:** [Open an issue](https://code.cs.earlham.edu/njalshe23/webdev-migrate/-/issues)

**When reporting an issue, include:**
1. What you were trying to do
2. The exact command you ran
3. The error message (copy-paste, don't paraphrase)
4. Relevant logs from `/var/log/webdev-migrate/`

---

## Preventive Measures

**Avoid problems before they start:**

### 1. Regular Maintenance

```bash
# Weekly: Clean old backups
sudo find /srv/backups/wp -type d -mtime +30 -delete

# Monthly: Check disk space
df -h /var/www /srv/backups

# Monthly: Verify backups
# (pick a random backup and test restore)
```

### 2. Test Before Production

```bash
# Always test on test sites first
webdev-migrate clone-to-test portfolios

# Test migration on test site
webdev-migrate migrate test-server:portfolios.test local:portfolios.test

# If it works, do production
```

### 3. Keep Tool Updated

```bash
# Check current version
webdev-migrate --version

# Check for updates
cd /path/to/webdev-migrate
git pull origin main

# Redeploy
sudo cp webdev-migrate /usr/local/bin/
```

### 4. Document Your Setup

Keep notes about:
- Which sites are on which servers
- Special plugin configurations
- Custom migration workflows
- Known issues with specific sites

**Future you will thank present you.**

---

**Still having issues? Check [TRAINING.md](TRAINING.md) for detailed tutorials or [MULTI-SERVER.md](MULTI-SERVER.md) for cross-server specific problems.**
