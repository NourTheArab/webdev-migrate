# webdev-migrate Walkthroughs

Detailed step-by-step walkthroughs for common migration scenarios.

## Table of Contents

1. [Migrate a Single Site: web → web-urey](#walkthrough-1-migrate-a-single-site-web--web-urey)
2. [Clone Live → Test](#walkthrough-2-clone-live--test)
3. [Promote Multisite Subsite to Standalone](#walkthrough-3-promote-multisite-subsite-to-standalone)

---

## Walkthrough 1: Migrate a Single Site: web → web-urey

**Scenario:** You need to move the portfolios site from the old web server to the new web-urey server.

**Time Required:** 30-60 minutes (depending on site size)

**Prerequisites:**
- SSH access to both web and web-urey
- Sudo privileges on both servers
- DNS information handy (for final cutover)

### Phase 1: Preparation (5 minutes)

**Step 1.1:** Connect to the source server (web)
```bash
ssh username@web
```

**Step 1.2:** Check the source site is healthy
```bash
webdev-migrate inventory portfolios.cs.earlham.edu
```

**Expected output:**
- Shows WordPress path
- Shows database name
- Shows it's working
- No errors

**If you see errors:** Fix them before continuing!

**Step 1.3:** Review the site information and note:
- WordPress path: `/var/www/wordpress-portfolios`
- Database name: `wp_portfolios`
- Site size: (note this for disk space planning)

**Step 1.4:** Connect to destination server (web-urey) in a new terminal
```bash
ssh username@web-urey
```

**Step 1.5:** Check disk space on destination
```bash
df -h /var/www
```

Make sure you have at least 2x the source site size available.

### Phase 2: Dry Run (5 minutes)

**Step 2.1:** On either server, run a dry run of the migration
```bash
webdev-migrate --dry-run migrate web:portfolios web-urey:portfolios
```

**Step 2.2:** Review the plan output carefully. It should show:
```
Migration Plan:
1. Create backup of source site
2. Transfer backup to destination
3. Restore backup on destination
4. Update URLs and configuration
5. Configure Apache on destination
6. Run health checks
```

**Step 2.3:** Make sure you understand each step. If anything is unclear, ask for help now.

### Phase 3: Execute Migration (20-40 minutes)

**Step 3.1:** Start the actual migration
```bash
webdev-migrate migrate web:portfolios web-urey:portfolios
```

**Step 3.2:** Monitor the output. You'll see:
- `[STEP] Creating backup of source site` - This may take several minutes
- `[STEP] Transferring backup to destination` - Progress bars will show
- `[STEP] Restoring on destination` - Another few minutes
- `[STEP] Updating URLs` - Quick
- Prompts for confirmation - Read carefully before confirming

**Step 3.3:** When asked for destination WordPress path, you can:
- Accept the default: `/var/www/wordpress-portfolios`
- Or specify a different path

**Step 3.4:** The tool will handle:
- Creating the database on web-urey
- Importing all data
- Setting correct permissions
- Updating URLs from web to web-urey

**Step 3.5:** At the end, you'll see instructions for Apache configuration. **Don't skip this!**

### Phase 4: Apache Configuration (10 minutes)

**Step 4.1:** On web-urey, create the Apache vhost configuration

If you have a template on web, copy it:
```bash
# On web
sudo cat /etc/apache2/sites-enabled/portfolios.cs.earlham.edu-ssl.conf

# Copy the output, then on web-urey:
sudo nano /etc/apache2/sites-available/portfolios.cs.earlham.edu-ssl.conf
# Paste and adjust paths if needed
```

Or create from scratch using the example from the tool's output.

**Step 4.2:** Key things to check in the vhost file:
```apache
ServerName portfolios.cs.earlham.edu
DocumentRoot /var/www/wordpress-portfolios

# SSL certificate paths
SSLCertificateFile /etc/letsencrypt/live/cs.earlham.edu/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/cs.earlham.edu/privkey.pem

<Directory /var/www/wordpress-portfolios>
    AllowOverride All
    Require all granted
</Directory>
```

**Step 4.3:** Enable the site
```bash
sudo a2ensite portfolios.cs.earlham.edu-ssl.conf
```

**Step 4.4:** Test Apache configuration
```bash
sudo apache2ctl configtest
```

**Expected output:** `Syntax OK`

**If you get errors:** Fix them before proceeding!

**Step 4.5:** Reload Apache
```bash
sudo systemctl reload apache2
```

### Phase 5: Testing (10 minutes)

**Step 5.1:** Run health check on the new server
```bash
webdev-migrate healthcheck portfolios.cs.earlham.edu web-urey
```

**Step 5.2:** Check each item:
- ✓ WordPress files present
- ✓ Database connection works
- ✓ URLs configured correctly
- ✓ Apache vhost enabled
- ✓ File permissions correct

**If any checks fail:** Fix them now!

**Step 5.3:** Test manually by adding web-urey IP to your hosts file

On your local computer (not the server):
```bash
# Mac/Linux: edit /etc/hosts
# Windows: edit C:\Windows\System32\drivers\etc\hosts
# Add line:
IP_OF_WEB_UREY portfolios.cs.earlham.edu
```

**Step 5.4:** Open browser and visit:
```
https://portfolios.cs.earlham.edu
```

**Step 5.5:** Test thoroughly:
- [ ] Homepage loads
- [ ] Can log in to wp-admin
- [ ] Images display correctly
- [ ] PDFs download correctly
- [ ] Navigation works
- [ ] Forms work (if any)

**Step 5.6:** Remove the hosts file entry when done testing

### Phase 6: DNS Cutover (Coordinate with Porter)

**DO NOT DO THIS STEP WITHOUT APPROVAL!**

**Step 6.1:** Prepare cutover plan
```
OLD: portfolios.cs.earlham.edu → IP_OF_WEB
NEW: portfolios.cs.earlham.edu → IP_OF_WEB_UREY
```

**Step 6.2:** Email or Slack Porter with:
- Domain: portfolios.cs.earlham.edu
- New IP: [IP of web-urey]
- Timing: [When you want cutover]
- Rollback plan: [Can point back to old IP if needed]

**Step 6.3:** After DNS change, verify:
```bash
# Check DNS propagation
nslookup portfolios.cs.earlham.edu

# Test the site
webdev-migrate healthcheck portfolios.cs.earlham.edu web-urey
```

**Step 6.4:** Monitor for 24-48 hours:
- Check Apache error logs: `sudo tail -f /var/log/apache2/error.log`
- Check site accessibility
- Watch for user reports

### Phase 7: Cleanup (After 1 week)

**Only do this after confirming everything works!**

**Step 7.1:** On old web server, you can now:
- Disable the site: `sudo a2dissite portfolios.cs.earlham.edu-ssl.conf`
- Archive the files: `sudo tar -czf /tmp/portfolios-old.tar.gz /var/www/wordpress-portfolios`
- Keep the archive for 30 days, then delete

---

## Walkthrough 2: Clone Live → Test

**Scenario:** You want to test some plugin updates on the portfolios site before applying them to the live site.

**Time Required:** 15-20 minutes

**Prerequisites:**
- SSH access to the server
- Sudo privileges

### Step-by-Step

**Step 1:** Connect to server
```bash
ssh username@web-urey
```

**Step 2:** Start the cloning process
```bash
webdev-migrate clone-to-test portfolios
```

**Step 3:** Review the plan
```
This will:
  1. Create test database: wp_testing_portfolios
  2. Copy database: wp_portfolios → wp_testing_portfolios
  3. Sync files: /var/www/wordpress-portfolios → /var/www/wordpress-testing-portfolios
  4. Update URLs: portfolios.cs.earlham.edu → portfolios.testing.cs.earlham.edu
  5. Add robots.txt noindex
```

**Step 4:** Confirm `y` when asked

**Step 5:** Wait for completion (5-10 minutes depending on site size)

**Step 6:** Follow the Apache configuration instructions shown

Create vhost for testing domain:
```bash
# Copy live config as template
sudo cp /etc/apache2/sites-available/portfolios.cs.earlham.edu-ssl.conf \
   /etc/apache2/sites-available/portfolios.testing.cs.earlham.edu-ssl.conf
```

**Step 7:** Edit the new config
```bash
sudo nano /etc/apache2/sites-available/portfolios.testing.cs.earlham.edu-ssl.conf
```

Change:
- `ServerName` to `portfolios.testing.cs.earlham.edu`
- `DocumentRoot` to `/var/www/wordpress-testing-portfolios`

**Step 8:** Enable test site
```bash
sudo a2ensite portfolios.testing.cs.earlham.edu-ssl.conf
sudo systemctl reload apache2
```

**Step 9:** Test the site
```bash
webdev-migrate healthcheck portfolios.testing.cs.earlham.edu
```

**Step 10:** Access test site in browser:
```
https://portfolios.testing.cs.earlham.edu
```

**Step 11:** Now you can safely:
- Update plugins
- Test new themes
- Try configuration changes
- All without affecting live site!

**Step 12:** When satisfied with testing, promote to live:
```bash
webdev-migrate promote-to-live portfolios
```

**Warning:** Promotion is destructive - it replaces live with test!

---

## Walkthrough 3: Promote Multisite Subsite to Standalone

**Scenario:** The earlhamword.com blog (blog_id 10) in the cs-wp multisite needs to become its own standalone WordPress site.

**Time Required:** 45-90 minutes

**Prerequisites:**
- SSH access
- Sudo privileges
- Know the blog_id (find via network admin or ask)
- Target domain decided (earlhamword.com)

### Phase 1: Investigation (10 minutes)

**Step 1.1:** Connect to server
```bash
ssh username@web
```

**Step 1.2:** List all subsites in the multisite
```bash
webdev-migrate list-subsites /var/www/cs-wp
```

**Expected output:**
```
+----------+----------------+-------------------------------+
| blog_id  | domain         | path                          |
+----------+----------------+-------------------------------+
| 1        | cs.earlham.edu | /                            |
| 5        | webdev.cs...   | /                            |
| 10       | earlhamword... | /                            |
+----------+----------------+-------------------------------+
```

**Step 1.3:** Confirm blog_id 10 is earlhamword.com

**Step 1.4:** Check current uploads
```bash
ls -lah /var/www/cs-wp/wp-content/uploads/sites/10/
```

Note the size - you'll need this space for the standalone site.

**Step 1.5:** Inventory the multisite
```bash
webdev-migrate inventory cs.earlham.edu
```

Note the database name (probably `cs_wp`)

### Phase 2: Backup Everything (10 minutes)

**Step 2.1:** Backup the entire multisite BEFORE making changes
```bash
webdev-migrate backup /var/www/cs-wp cs-wp multisite
```

**This is critical!** If something goes wrong, you need this backup.

**Step 2.2:** Note the backup location. Write it down:
```
Backup: /srv/backups/wp/cs-wp/multisite/TIMESTAMP
```

### Phase 3: Dry Run (5 minutes)

**Step 3.1:** Test the promotion without actually doing it
```bash
webdev-migrate --dry-run promote-subsite /var/www/cs-wp 10 earlhamword.com
```

**Step 3.2:** Review the plan:
```
This process:
  1. Backs up entire multisite
  2. Exports subsite tables
  3. Creates new standalone WordPress
  4. Imports and converts tables
  5. Copies uploads from sites/10/
  6. Removes multisite constants
  7. Updates URLs
```

**Step 3.3:** Make sure you understand each step

### Phase 4: Execute Promotion (30-45 minutes)

**Step 4.1:** Run the actual promotion
```bash
webdev-migrate promote-subsite /var/www/cs-wp 10 earlhamword.com
```

**Step 4.2:** When asked to confirm, you must type exactly:
```
PROMOTE
```

This is a safety measure because this operation is complex.

**Step 4.3:** The tool will now:
- Create another backup (safety)
- Export tables for blog_id 10
- Create new database `wp_earlhamword`
- Convert table names (wp_10_posts → wp_posts)
- Copy users/usermeta tables
- Create new WordPress directory: `/var/www/wordpress-earlhamword`

**Step 4.4:** Watch for any errors. If you see errors about:
- **Missing columns:** The tool will try to fix these
- **Table not found:** Might indicate wrong blog_id - STOP and check
- **Permission denied:** Need sudo

**Step 4.5:** The uploads copy may take several minutes if large

**Step 4.6:** Near the end, it creates a clean wp-config.php without multisite constants

### Phase 5: Post-Promotion Configuration (15 minutes)

**Step 5.1:** Apache configuration

Create vhost for earlhamword.com:
```bash
sudo nano /etc/apache2/sites-available/earlhamword.com-ssl.conf
```

Template:
```apache
<VirtualHost *:80>
    ServerName earlhamword.com
    ServerAlias www.earlhamword.com
    DocumentRoot /var/www/wordpress-earlhamword
    
    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName earlhamword.com
    ServerAlias www.earlhamword.com
    DocumentRoot /var/www/wordpress-earlhamword
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/earlhamword.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/earlhamword.com/privkey.pem
    
    <Directory /var/www/wordpress-earlhamword>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/earlhamword-error.log
    CustomLog ${APACHE_LOG_DIR}/earlhamword-access.log combined
</VirtualHost>
```

**Step 5.2:** SSL Certificate

If the website, for example, earlhamword.com doesn't have a cert yet (you can also potentially talk with Porter and he'll sort that part out for you):
```bash
sudo certbot --apache -d earlhamword.com -d www.earlhamword.com
```

**Step 5.3:** Enable site
```bash
sudo a2ensite earlhamword.com-ssl.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### Phase 6: Verification and Testing (20 minutes)

**Step 6.1:** Run health check
```bash
webdev-migrate healthcheck earlhamword.com
```

**Step 6.2:** Check for common issues after multisite conversion

**Issue 1: User roles**
```bash
sudo -u www-data wp --path=/var/www/wordpress-earlhamword user list
```

Make sure admin users have correct roles. If not:
```bash
sudo -u www-data wp --path=/var/www/wordpress-earlhamword user add-role USERNAME administrator
```

**Issue 2: Missing tables**

Check if wp_options has correct data:
```bash
sudo -u www-data wp --path=/var/www/wordpress-earlhamword option list
```

You should see `siteurl` and `home` with correct domain.

**Issue 3: Media files**

Test that images and PDFs load:
```bash
# Pick a random image from uploads
ls /var/www/wordpress-earlhamword/wp-content/uploads/

# Test it loads
curl -I https://earlhamword.com/wp-content/uploads/2024/01/some-image.jpg
```

Should return `200 OK`

**Step 6.3:** Test login
```
https://earlhamword.com/wp-admin
```

Login with an admin account from the multisite.

**Step 6.4:** Check dashboard
- Go through each admin page
- Check Posts, Pages, Media
- Verify nothing looks broken

**Step 6.5:** Test frontend
- Visit homepage
- Test navigation
- Click several posts/pages
- Test search if available

**Step 6.6:** Run URL audit to catch any remaining issues
```bash
webdev-migrate url-audit /var/www/wordpress-earlhamword
```

If it finds URLs pointing to cs.earlham.edu, replace them:
```
Old: https://cs.earlham.edu
New: https://earlhamword.com
```

### Phase 7: DNS and Go-Live

**Step 7.1:** Update DNS for earlhamword.com to point to the web server

Contact Porter.

**Step 7.2:** Wait for DNS propagation (can take up to 48 hours)

Check with:
```bash
nslookup earlhamword.com
```

**Step 7.3:** Monitor logs for the first few days
```bash
sudo tail -f /var/log/apache2/earlhamword-error.log
```

### Phase 8: Cleanup (After 2 weeks)

**Only after confirming everything works!**

**What you can do:**
- Leave the subsite in multisite as archive (disabled)
- Or completely remove it from multisite database
- Keep backups for at least 90 days

**What NOT to do:**
- Don't remove from multisite immediately
- Don't delete the standalone site thinking you'll go back to multisite

---

## Troubleshooting Common Issues

### Issue: "Table doesn't exist"

**During multisite promotion**

**Cause:** Wrong blog_id or missing tables

**Fix:**
1. Double-check blog_id with `list-subsites`
2. Look in database:
```bash
mysql -u root cs_wp -e "SHOW TABLES LIKE 'wp_10_%';"
```
3. If no tables found, blog_id is wrong

### Issue: "Permission denied" on uploads

**After migration or cloning**

**Cause:** Wrong file ownership

**Fix:**
```bash
sudo chown -R www-data:www-data /var/www/SITE-PATH
sudo chmod -R 755 /var/www/SITE-PATH
sudo find /var/www/SITE-PATH -type f -exec chmod 644 {} \;
```

### Issue: Database import fails with "Access denied"

**During restore or migration**

**Cause:** Database user doesn't have permissions

**Fix:**
```bash
sudo mysql -e "GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

### Issue: URLs aren't updating after search-replace

**After migration**

**Cause:** Serialized data or plugin-specific storage

**Fix:**
1. Run URL audit to find remaining occurrences
2. For plugin-specific issues (like dFlip), might need manual database edits
3. Clear all caches:
```bash
sudo -u www-data wp --path=/var/www/SITE cache flush
sudo -u www-data wp --path=/var/www/SITE transient delete --all
```

### Issue: "Site is not accessible" after migration

**Causes and fixes:**

**Check 1: Apache**
```bash
sudo systemctl status apache2
sudo apache2ctl configtest
```

**Check 2: Vhost enabled**
```bash
ls -la /etc/apache2/sites-enabled/ | grep SITENAME
```

**Check 3: DNS**
```bash
nslookup DOMAIN
```

**Check 4: Firewall**
```bash
sudo ufw status
```

**Check 5: SSL Certificate**
```bash
sudo certbot certificates
```

---

## Quick Reference

### Before Any Operation

```bash
# 1. Check current state
webdev-migrate inventory DOMAIN

# 2. Backup first
webdev-migrate backup /var/www/SITE SLUG ENV

# 3. Dry run if complex
webdev-migrate --dry-run COMMAND args...

# 4. Have rollback plan ready
```

### After Any Operation

```bash
# 1. Health check
webdev-migrate healthcheck DOMAIN

# 2. Test manually
# Visit site in browser

# 3. Check logs
tail -100 /var/log/webdev-migrate/webdev-migrate-TIMESTAMP.log

# 4. Monitor
sudo tail -f /var/log/apache2/error.log
```

### Emergency Rollback

```bash
# Find latest backup
ls -lt /srv/backups/wp/SITE/ENV/

# Restore it
webdev-migrate restore /srv/backups/wp/SITE/ENV/TIMESTAMP /var/www/SITE
```

---

**End of Walkthroughs**

For more help, see:
- README.md - Complete reference
- TRAINING.md - Beginner guide
- `webdev-migrate --help` - Command help
