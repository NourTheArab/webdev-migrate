# Philosophy & Design Decisions

**Why webdev-migrate exists and how it's built**

---

## The Core Problem

Earlham's WordPress infrastructure had **knowledge trapped in people's heads**:
- Charles (Class of 2026) knew how to migrate multisite
- Porter knows the server network topology
- Previous students attampted to create documentation and code

When people left, **knowledge left with them**.

This tool is my attempt to fix that.

---

## Design Principles

### 1. **Teach, Don't Just Do**

**Bad approach:** Silent automation that works until it doesn't, or a batch of scripts that make sense to their maker.

**My approach:** Explain *why* at every step.

```bash
# BAD: Silent failure
mysql -u user -p'password' db < backup.sql
# (fails silently if password wrong)

# GOOD: Explain what's happening
log_step "Importing database backup..."
if ! mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$backup_sql"; then
    log_error "Database import failed"
    log_info "Common causes:"
    log_info "  • Wrong database credentials"
    log_info "  • Database doesn't exist (create it first)"
    log_info "  • Insufficient permissions"
    return 1
fi
```

**Why:** The next person learns from errors, not just panics.

---

###

 2. **THE 8 FACTS Standard**

Every WordPress site has the same 8 critical pieces of information:

1. **Domain** - What URL?
2. **Server** - Which machine?
3. **Path** - Where are the files?
4. **Database** - Name, user, host
5. **Environment** - Live or test?
6. **Multisite** - Standalone or part of network?
7. **Uploads** - Configuration and location
8. **Active Code** - Theme and plugin count

**Why this format?**

**Problem:** Everyone checks different things. New person doesn't know what matters.

**Solution:** Standardized checklist builds muscle memory. After 10 inventories, you *know* what to look for.

**Example:**
```
Domain: portfolios.cs.earlham.edu
Server: (XX) (XX)
WordPress Path: /var/www/wordpress-portfolios
Database: wp_portfolios (user: wpuser, host: localhost)
Environment: LIVE
Multisite: No (standalone installation)
Uploads: /var/www/wordpress-portfolios/wp-content/uploads
Theme: Divi (active) | Plugins: 23 active, 4 inactive
```

Every inventory looks like this. Every time. **Consistency = training**.

---

### 3. **Operations Must Be Lockable**

**The scenario:**
- Student A starts backing up earlhamword.com
- Student B starts migrating earlhamword.com
- Both operations write to the database
- **Data corruption**

**The solution:** File-based locking.

```bash
/var/lock/webdev-migrate/earlhamword.lock
```

Only one operation per site at a time. Operations clean up their locks.

**Why file-based?** Works across SSH sessions, survives terminal crashes, visible with `ls`.

---

### 4. **Safety Through Friction (For Destructive Ops)**

**Philosophy:** Make dangerous things *slightly* annoying to prevent accidents.

**Example: promote-to-live**

```bash
# Step 1: Dry-run (mandatory, automatic)
DRY_RUN=true
show_migration_plan()
DRY_RUN=false

# Step 2: Confirmation string
echo "Type PROMOTE-LIVE to confirm:"
read confirmation
if [[ "$confirmation" != "PROMOTE-LIVE" ]]; then
    exit 1
fi

# Step 3: Execute
actually_promote()
```

**Why the confirmation string?** You have to *type* the words "PROMOTE-LIVE". Muscle memory kicks in: "Wait, am I sure?"

This is **intentional friction**. One second of typing prevents hours of rollback.

---

### 5. **Multisite is Special (And Painful)**

**WordPress Multisite is not intuitive:**
- Subsites share wp-config.php
- Each subsite has its own blog_id
- Table prefixes include blog_id (wp_2_posts, wp_3_options)
- Main site is blog_id=1
- URLs can be subdomain OR subdirectory

**My approach:**
- Always show blog_id in inventory
- Always show table prefix
- Warn when promoting a subsite (serialization issues)
- Separate multisite-specific docs

**Why:** Multisite bites new people HARD. I make it visible upfront.

---

### 6. **URLs Are Serialized (And That Breaks Everything)**

**The DFlip Plugin Problem:**

DFlip stores flipbook settings in `wp_postmeta` as **PHP serialized strings**:

```php
a:5:{s:4:"page";i:1;s:3:"url";s:45:"https://old.earlham.edu/wp-content/...pdf";}
```

Standard `wp search-replace` changes the URL but **breaks the string length**:

```php
a:5:{s:4:"page";i:1;s:3:"url";s:45:"https://new-longer.earlham.edu/wp-content/...pdf";}
                                ^^^^
                                WRONG! Still says s:45 but string is now 55 chars
```

PHP unserialize() fails. Plugin breaks. Pages blank.

**Solution:** `--deep` flag scans plugin metadata:

```bash
webdev-migrate url-audit --deep /var/www/site
```

Finds serialized URLs that standard search-replace missed.

**Why this matters:** I spent **weeks** debugging this on earlhamword.com. Now it takes 2 minutes.

---

### 7. **ProxyJump is Our Network Reality**

**Network topology:**
```
Laptop → jumphost.cs.earlham.edu → web (192.168.1.10)
                                  → web-urey (192.168.1.20)
```

Can't SSH directly to =web-urey, as an example, from outside campus. Must bounce through jumphost.

**Tool support:**
```bash
# Server profile saves this
SERVER_PROXY="jumphost.cs.earlham.edu"

# remote_exec builds the SSH command
ssh -J jumphost.cs.earlham.edu user@192.168.1.10 "command"
```

**Why:** Without ProxyJump support, cross-server migrations are manual hell.

---

### 8. **Backups Must Be Verifiable**

**Bad backup system:**
```bash
mysqldump db > backup.sql
tar czf backup.tar.gz files/
echo "Done!"
```

**Problems:**
- mysqldump might fail silently
- Tar might fail silently
- No way to verify backup worked

**My backup system:**
```bash
# 1. Estimate size first
show_size_estimate()

# 2. Create backup
mysqldump ... || { error "mysqldump failed"; return 1; }

# 3. Verify file exists and has content
[[ -f backup.sql.gz ]] || { error "Backup missing"; return 1; }
[[ -s backup.sql.gz ]] || { error "Backup empty"; return 1; }

# 4. Show actual size
du -h backup.sql.gz

# 5. Test restore (optional, for critical backups)
```

**Why:** A backup you can't restore is worthless. Verify immediately.

---

### 9. **Retention Policies Prevent Disk Bloat**

**Problem:** Backups accumulate forever. Disk fills up. Tool breaks.

**Solution:** Automatic cleanup.

```bash
# Default: Keep last 30 days
BACKUP_RETENTION_DAYS=30

# After each backup
find /srv/backups/wp -type d -mtime +30 -exec rm -rf {} \;
```

**Configurable:** Set in `~/.webdev-migrate.conf` if you want longer retention.

**Why:** Prevents "disk full" emergencies at 2am. I didn't experience them, thankfully, but it's a possibility worth building for.

---

### 10. **Error Messages Must Teach**

**Bad error:**
```
Error: Database connection failed
```

**Good error:**
```
✗ Database connection failed

Common causes:
  • Wrong credentials in wp-config.php
  • MySQL service not running (check: systemctl status mysql)
  • Database doesn't exist (create with: mysql -e "CREATE DATABASE ...")
  • Firewall blocking port 3306

Check credentials:
  DB_NAME: wp_site
  DB_USER: wpuser
  DB_HOST: localhost

Try manual connection:
  mysql -h localhost -u wpuser -p wp_site
```

**Why:** Errors are *teaching moments*. Help the person fix it themselves.

---

## Design Decisions (The "Why Did You Do It This Way?" FAQ)

### Q: Why Bash instead of Python/PHP?

**A:** Three reasons:

1. **Already installed:** Every server has Bash. No dependencies.
2. **Shell-native:** Most operations are shell commands anyway (mysql, mysqldump, tar, ssh, rsync)
3. **Readable:** Bash is verbose but clear. Future maintainer can read it.

**Trade-off:** Bash is clunky for complex logic. But readability > elegance.

---

### Q: Why file locks instead of database locks?

**A:** Works across SSH sessions.

If Student A SSH's to web-urey and starts a backup, Student B's SSH session can see the lock:

```bash
ls /var/lock/webdev-migrate/
# earlhamword.lock  <- Visible to everyone
```

Database locks only work within one DB connection. File locks work across anything.

---

### Q: Why confirmation strings instead of "Are you sure? (y/N)"?

**A:** Typos.

```bash
# Easy to fatfinger
Are you sure? y  ← meant to type 'n', hit 'y' by muscle memory

# Harder to fatfinger
Type PROMOTE-LIVE to confirm: PROMOTE-LIVE  ← requires conscious thought
```

Typing the full phrase makes you *think* about what you're confirming.

---

### Q: Why THE 8 FACTS and not more/less?

**A:** Tested in production.

Started with 12 facts. Too overwhelming. Trimmed to 5. Too sparse (missed critical info). Settled on 8.

These 8 cover:
- Location (domain, server, path)
- Data (database)
- Safety (environment)
- Type (multisite)
- Config (uploads)
- Code (theme/plugins)

Enough to make decisions, not so much you ignore it.

---

### Q: Why separate `--deep` flag for URL audit?

**A:** Performance.

Standard scan checks `wp_options` and `wp_posts`. Takes ~10 seconds.

Deep scan checks `wp_postmeta` and `wp_usermeta`. Takes ~30 seconds on large sites.

Most migrations don't need deep scan. When you do (DFlip, galleries), the flag is there.

**Principle:** Fast by default, thorough when requested.

---

### Q: Why auto-cleanup backups instead of letting users decide?

**A:** Disk space failures are silent killers.

You don't notice disk is 99% full until:
- Backup fails
- WordPress can't upload media
- MySQL crashes
- Server becomes unstable

Auto-cleanup prevents this. 30 days is configurable if you need more, or less. Our systems have their own back-up routine (thank you Porter) but if this tool was to be used elsewhere, this is another safety guard.

**Safety:** Cleanup happens *after* new backup succeeds. Never deletes if new backup fails.

---

## 🎓 Lessons Learned (What I'd Do Differently)

### Lesson 1: Start with --help sooner

Early versions had no `--help`. Users had to read docs.

**Fix:** Added comprehensive `--help` in v1.1.

**Lesson:** Even good docs don't get read. Built-in help does.

---

### Lesson 2: Log everything

Early versions logged errors. Not info.

**Problem:** "It failed but I don't know where."

**Fix:** Every operation logs to `/var/log/webdev-migrate/`. Timestamped. Searchable.

**Lesson:** Logs are evidence. When debugging, logs win arguments.

---

### Lesson 3: Dry-run should be automatic for destructive ops

v1.0 had `--dry-run` as optional flag.

**Problem:** People may forget to use it. Mistakes could happen.

**Fix:** v1.2 made dry-run *automatic* for promote-to-live. Can't skip it.

**Lesson:** Don't make safety optional. Make it the default path.

---

### Lesson 4: Test with real data, not toy examples

Tested early versions with small test sites.

**Problem:** Real sites (earlhamword.com) broke in ways test sites didn't:
- DFlip serialization
- Multisite subsites
- Large uploads (timeouts)

**Fix:** Use production-size test data.

**Lesson:** Toy examples hide real-world pain.

---

## Future Directions (Ideas for v1.4+)

### Idea 1: Automated Testing

Add self-test mode:
```bash
webdev-migrate --self-test
```

Creates dummy site, tests all operations, cleans up.

**Why:** Catch regressions before deploying.

---

### Idea 2: Backup Compression Options

Currently: gzip only.

Future: zstd (faster, better compression)

**Why:** Large media libraries take forever to back up.

---

### Idea 3: Migration Templates

Save common migration patterns:
```bash
# Save template
webdev-migrate save-template "test-to-live" \
    "promote test → live with URL update"

# Use template
webdev-migrate use-template "test-to-live" portfolios
```

**Why:** Repetitive migrations become one command.

---

### Idea 4: Metrics Dashboard

Track:
- How many migrations ran
- Success rate
- Common errors
- Average time per operation

**Why:** Identify pain points, improve tool.

---

## Final Thoughts

This tool represents **4 months of production experience** condensed into code.

Every error message has a story. Every confirmation string prevented a real mistake. Every design decision came from actual pain.

If you maintain this, you'll have different pain points. **Add your solutions.** Update this doc. Explain your thinking.

The goal isn't perfection. The goal is **passing knowledge down**.

Good luck, future person. You've got this.

— Nour

---

**Questions about design decisions? Open an issue, or reach out to @NourTheArab anywhere on Social Media. Let's discuss.**
