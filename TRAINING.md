# webdev-migrate Training Guide

**For Beginners Who Are New to Web Development**

This guide will teach you everything you need to know to use the webdev-migrate tool, even if you've never worked with WordPress or web servers before.

## What You'll Learn

1. Basic concepts (WordPress, servers, databases)
2. How to use the tool safely
3. Step-by-step walkthroughs
4. What to do when things go wrong

## Part 1: Basic Concepts

### What is WordPress?

WordPress is software that runs websites. Think of it like Microsoft Word, but for websites instead of documents. It consists of:

- **Files** - The WordPress code, themes, plugins, and uploaded media
- **Database** - Where all content (posts, pages, settings) is stored
- **Configuration** - A file (wp-config.php) that connects files to database

### What is a Server?

A server is just a computer that's always on and connected to the internet. At Earlham (at the time of writing and development at least):
- **web** - The old server
- **web-urey** - The new server
- Both run Linux 

### Important Locations

On our servers, WordPress sites live in specific places:

```
/var/www/                     ← All websites live here
  ├── wordpress-portfolios/   ← One website
  ├── wordpress-hop/          ← Another website
  └── cs-wp/                  ← A "multisite" (multiple sites in one)

/srv/backups/wp/              ← Where backups are saved
  └── portfolios/
      └── live/
          └── 20260212-120000/  ← A backup from Feb 12, 2026 at 12:00 PM
```

### What is a Database?

A database is like a filing cabinet for your website's content. Each WordPress site has its own database with a name like:
- `wp_portfolios` - Database for portfolios site
- `wp_testing_portfolios` - Database for testing version

## Part 2: Connecting to Servers

### Using SSH

SSH is how you connect to a server. Think of it like remote desktop, but text-only. If you are completely unfamiliar with it, hit me up and we can have a mini crash course!

**On Mac/Linux:**
```bash
ssh username@web.cs.earlham.edu
```

**On Windows:**
Use PuTTY or Windows Terminal. I don't practice what I preach. I LOVE VSCode. You can SSH there as well :)

**Once Connected:**
You'll see a prompt like:
```
username@web:~$
```

This means you're now controlling the server (for the sake of the example, not fully).

### Becoming Root (Admin)

Some commands need admin privileges. Use `sudo`:
```bash
sudo command-here
```

You'll be asked for your password. This is normal and safe. If you take CyberSecurity or speak with Charlie or Porter they can tell you how to configure passwordless SSH and more. 

## Part 3: Using webdev-migrate

### Starting the Tool

The easiest way is interactive mode. Just type:
```bash
webdev-migrate
```

You'll see a menu like this:
```
1)  Inventory a site (show details)
2)  Backup a site
3)  Restore a site from backup
...
0)  Exit
```

### Your First Command: Inventory

Let's look at a website to understand what we have.

1. Run the tool:
```bash
webdev-migrate
```

2. Choose option `1` (Inventory)

3. When asked for domain, type:
```
portfolios.cs.earlham.edu
```

4. When asked for host, press Enter (uses localhost)

5. You'll see a report showing:
   - Where the site files are
   - What database it uses
   - How big it is
   - If it's working properly

**What This Means:**
Now you understand one site. You can look at any site this way!

## Part 4: Making Backups

**Rule #1: Always backup before changes!**

### Creating Your First Backup

1. Start the tool:
```bash
webdev-migrate
```

2. Choose option `2` (Backup a site)

3. Answer the questions:
   - **WordPress path**: `/var/www/wordpress-portfolios`
   - **Site slug**: `portfolios`
   - **Environment**: `live` (just press Enter)
   - **Host**: `localhost` (just press Enter)

4. Wait. The tool will:
   - Save the database
   - Save all uploaded files
   - Create a restore helper script

5. When done, you'll see:
```
Backup Location: /srv/backups/wp/portfolios/live/20250214-120000
```

**Important:** Write this location down! You need it to restore.

### Understanding Backups

Each backup contains:
- `db.sql.gz` - Your database (compressed)
- `uploads.tar.gz` - All images, PDFs, media
- `wp-config.php` - Configuration
- `restore.sh` - Helper to put it back

Think of it like a ZIP file of your entire website.

## Part 5: Common Tasks

### Task 1: Check if a Site is Healthy

**When to do this:** After any changes, or if something seems wrong.

```bash
webdev-migrate healthcheck portfolios.cs.earlham.edu
```

The tool will check:
- ✓ Files are present
- ✓ Database works
- ✓ URLs are correct
- ✓ Apache (web server) configured
- ✓ Permissions are right
- ✓ Site loads in browser

**Green ✓** = Good!
**Yellow ⚠** = Warning, check it
**Red ✗** = Problem, needs fixing

### Task 2: Create a Testing Copy

**When to do this:** You want to try changes without risking the live site.

1. Run:
```bash
webdev-migrate clone-to-test portfolios
```

2. Confirm when asked

3. This creates:
   - New database: `wp_testing_portfolios`
   - New files: `/var/www/wordpress-testing-portfolios`
   - New URL: `portfolios.testing.cs.earlham.edu`

4. You'll see instructions for Apache setup - follow them!

**Now you have two sites:**
- Live: `portfolios.cs.earlham.edu` (real users see this)
- Test: `portfolios.testing.cs.earlham.edu` (only you see this)

Make changes on TEST first. When happy, promote to LIVE.

### Task 3: Moving a Site to New Server

**When to do this:** Migrating from web to web-urey. Or similar scenarios.

**Before You Start:**
1. Make sure you have SSH access to both servers
2. Do a health check on the source site
3. Have the DNS info ready (ask Porter)

**Steps:**

1. First, look at the site on old server:
```bash
ssh username@web
webdev-migrate inventory portfolios.cs.earlham.edu
```

2. Try a dry run (doesn't actually do anything):
```bash
webdev-migrate --dry-run migrate web:portfolios web-urey:portfolios
```

Read the plan. Make sure it looks right.

3. Do the actual migration:
```bash
webdev-migrate migrate web:portfolios web-urey:portfolios
```

This will:
- Create backup on web
- Transfer to web-urey
- Set up on web-urey
- Update URLs

4. Follow the Apache configuration instructions shown

5. Test the new site:
```bash
ssh username@web-urey
webdev-migrate healthcheck portfolios.cs.earlham.edu
```

6. **Don't change DNS yet!** Test thoroughly first.

7. When ready, ask Porter to update DNS

### Task 4: Fixing URL Problems

**When to do this:** Site has wrong URLs (like test URLs in live site).

1. Run the audit:
```bash
webdev-migrate url-audit /var/www/wordpress-portfolios
```

2. Review what it finds

3. If it finds problems, it will ask if you want to fix them

4. Enter the old URL and new URL:
   - Old: `https://portfolios.testing.cs.earlham.edu`
   - New: `https://portfolios.cs.earlham.edu`

5. Confirm and it will replace all occurrences

## Part 6: Safety and Best Practices

### Rule 1: Always Backup First

Before ANY change:
```bash
webdev-migrate backup /var/www/site-name site-name live
```

### Rule 2: Test on Testing Environment

1. Create test copy: `clone-to-test`
2. Make changes on test
3. Test thoroughly
4. Only then promote to live: `promote-to-live`

### Rule 3: Use Dry Run

For complex operations, try `--dry-run` first:
```bash
webdev-migrate --dry-run migrate web:site web-urey:site
```

This shows you what would happen without actually doing it.

### Rule 4: Read the Logs

Every operation creates a log file:
```
/var/log/webdev-migrate/webdev-migrate-20250214-120000.log
```

If something goes wrong, read this file. It has all the details.

### Rule 5: Ask for Help

If you're unsure:
1. Use dry run
2. Check the logs
3. Ask a teammate
4. Contact Nour or Porter

## Part 7: What Can Go Wrong

### Problem 1: "Permission denied"

**What happened:** You don't have admin rights for this operation.

**Fix:** Use sudo:
```bash
sudo webdev-migrate ...
```

Or ask Porter to add you to the right groups.

### Problem 2: "Database connection failed"

**What happened:** Can't connect to the database.

**Check:**
1. Is MySQL running?
```bash
sudo systemctl status mysql
```

2. Are credentials in wp-config.php correct?

3. Does the database exist?
```bash
mysql -u root -e "SHOW DATABASES;"
```

**Fix:** Usually need Porter's help for database issues. Could also be an interesting lesson if you ask AI. Make sure not to share any sensitive data though.

### Problem 3: "Site not accessible" in health check

**What happened:** Website doesn't load.

**Check:**
1. Is Apache running?
```bash
sudo systemctl status apache2
```

2. Is the vhost enabled?
```bash
ls -la /etc/apache2/sites-enabled/
```

3. Any errors in Apache logs?
```bash
sudo tail -50 /var/log/apache2/error.log
```

**Fix:**
```bash
# Restart Apache
sudo systemctl restart apache2

# If that doesn't work, check Apache config
sudo apache2ctl configtest
```

### Problem 4: Operation Failed Mid-Way

**Don't panic!**

1. Check the log file (path shown at start)

2. The tool makes backups before destructive operations.

3. To restore:
```bash
# Find latest backup
ls -lt /srv/backups/wp/site-name/live/

# Restore it
webdev-migrate restore /srv/backups/wp/site-name/live/TIMESTAMP /var/www/site
```

## Part 8: Glossary

**Apache** - The web server software (makes sites accessible via browser)

**Backup** - A copy of files and database that can be restored

**Blog ID** - In multisite, each subsite has a number (like 5, 10, etc.)

**Clone** - Make an exact copy

**Database** - Where content is stored (posts, pages, settings)

**DNS** - System that connects domain names to server IP addresses

**Domain** - The website address (like portfolios.cs.earlham.edu)

**Dry Run** - Simulate without actually doing

**Host** - The server computer (web, web-urey, or localhost)

**Localhost** - The current machine you're on

**Migration** - Moving a site from one server to another

**Multisite** - One WordPress with multiple sites inside (we're phasing these out)

**Root** - Administrator/superuser account

**Slug** - Short name for a site (like "portfolios")

**SSH** - Secure Shell, how you connect to servers

**Sudo** - Command to run something as administrator

**URL** - Web address (https://site.cs.earlham.edu)

**VHost** - Virtual Host, Apache configuration for a site

**WP-CLI** - WordPress Command Line Interface (`wp` command)

## Part 9: Practice Exercises

### Exercise 1: Get Familiar

1. Connect to web server
2. Run `webdev-migrate` (no arguments)
3. Choose Inventory
4. Look at a site
5. Exit

**Goal:** Get comfortable with the interface.

### Exercise 2: Read a Backup

1. Find a backup:
```bash
ls /srv/backups/wp/*/live/
```

2. Look inside one:
```bash
ls /srv/backups/wp/portfolios/live/TIMESTAMP/
```

3. Read the manifest:
```bash
cat /srv/backups/wp/portfolios/live/TIMESTAMP/manifest.json
```

**Goal:** Understand what backups contain.

### Exercise 3: Dry Run Practice

1. Try a fake migration:
```bash
webdev-migrate --dry-run migrate web:testsite web-urey:testsite
```

2. Read what it would do

3. Notice it says "[DRY RUN]" - nothing actually happened!

**Goal:** Get comfortable with dry run mode.


### Important Paths

```
/var/www/                     Websites
/srv/backups/wp/              Backups
/var/log/webdev-migrate/      Tool logs
/etc/apache2/sites-enabled/   Active websites
```

### Help

```bash
webdev-migrate --help         Full help
webdev-migrate --dry-run ...  Test safely
webdev-migrate --verbose ...  See details
```

### Emergency

```bash
# View recent logs
ls -lt /var/log/webdev-migrate/

# View a log
cat /var/log/webdev-migrate/LOGFILE

# Restore from backup
webdev-migrate restore BACKUP_PATH TARGET_PATH

# Get help
# Contact: Nour or Porter
```

## Conclusion

You now know how to:
- ✓ Understand WordPress basics
- ✓ Connect to servers
- ✓ Use webdev-migrate safely
- ✓ Backup and restore sites
- ✓ Perform common tasks
- ✓ Handle problems

Remember: Always backup, test first, and ask for help when unsure!

**Next Steps:**
1. Practice with the exercises
2. Do a real backup (with supervision)
3. Try a clone-to-test operation
4. Gradually build confidence

**You've got this!** 
