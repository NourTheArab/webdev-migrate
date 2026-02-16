# webdev-migrate v1.4.1

**The WordPress Tool That Actually Makes Sense**  
*Built by a human who got frustrated and inherited a mess, for humans who will hopefully not experience that afterwards*

---

## Hi, I'm Nour

I built this because I was tired of:
- Scripts that half-worked
- Migrations that broke plugins  
- Testing environments that didn't match production
- Watching new people make the same mistakes

So I made **one tool that does everything right, once.**

This isn't just code. This is 4 months of debugging earlhamword.com's DFlip plugin, countless "why did the URLs break?" moments, and a lot of coffee. It's meant to be **passed down** — so the next person doesn't have to learn the hard way.

---

## Quick Start (30 Seconds)

```bash
# Install
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate

# Run
webdev-migrate

# That's it. Really.
```

**Never used it before?** Type `webdev-migrate` with no arguments. The interactive menu will guide you.

**[5-Minute Tutorial →](QUICKSTART.md)**

---

## What Can This Do?

### On One Server (Local Mode)
- **Inventory** — Show THE 8 FACTS about any site
- **Backup** — Create backups that actually work when you need them (with size estimation!)
- **Restore** — With automatic verification
- **Clone** — Make perfect test copies  
- **Health Check** — 7-point diagnostic
- **URL Audit** — Find plugin metadata issues (looking at you, DFlip)

### Across Servers (Multi-Server Mode) ← NEW in v1.3!
- **List sites** across multiple servers at once
- **Migrate** between servers with safety checks
- **SSH ProxyJump** support (because our network is complicated, and honestly it's way less complicated than other clusters.)
- **Server profiles** (save your configs, stop typing IPs)

All with **safety built in**:
- Operation locking (no concurrent chaos)
- Pre-migration validation (real checks, dry-runs)
- Rollback backups (undo button for migrations)
- Environment validation (can't mix live/test)
- Automatic backup cleanup (30 days retention, configurable)

---

## The Philosophy

**Three core principles:**

### 1. Beginner-Proof
New to WordPress migrations? This tool **teaches** as it works:
- Every prompt has inline help
- Errors explain what went wrong AND how to fix it
- "THE 8 FACTS" format builds muscle memory
- Validation mode lets you learn without fear

### 2. Production-Ready
Built from real production pain:
- Used on earlhamword.com (multisite, 50+ ghost subsites that weren't terminated properly)
- Handles DFlip plugin weirdness, amongst other plugins that embed links in serialized data
- Deals with our ProxyJump network setup  

### 3. Pass-It-Down
This will outlive my time at Earlham:
- Comprehensive documentation (not just code comments, full documentation)
- Training guide for the next person, or an educational program to teach the server-side operations of wordpress.
- Walkthroughs for common tasks
- Philosophy doc explains WHY decisions were made

**[Read Full Philosophy →](docs/PHILOSOPHY.md)**

---

## What's New in v1.3?

### Multi-Server Capabilities
```bash
# Add a server once, save it forever
webdev-migrate add-server web 192.168.1.10 njalshe23 --proxy jumphost.cs.earlham.edu

# Migrate between servers
webdev-migrate multi-server
# Interactive wizard walks you through it
```

### Better Safety
- **Real validation** before migrations (WP-CLI check, DB health, write access)
- **Rollback backups** created automatically (asks first, handles failures)
- **Size estimation** before large backups (warns if >1GB)
- **Auto-cleanup** of old backups (30 days default, configurable)

### All Database Bugs Fixed
v1.2.1 had critical issues with database operations. v1.3.0 **fixes all 6 affected functions**. Backups, restores, clones, promotions — all work now.

**[Complete Changelog →](CHANGELOG.md)**

---

## Documentation

**Start Here:**
- **[QUICKSTART.md](QUICKSTART.md)** — 5-minute start (truly)
- **[PHILOSOPHY.md](docs/PHILOSOPHY.md)** — Why this exists, design decisions

**Learn:**
- **[TRAINING.md](docs/TRAINING.md)** — Complete beginner's guide (1 hour)
- **[WALKTHROUGHS.md](docs/WALKTHROUGHS.md)** — Real examples with context
- **[MULTI-SERVER.md](docs/MULTI-SERVER.md)** — Cross-server migration guide

**Reference:**
- **[IMPLEMENTATION.md](docs/IMPLEMENTATION.md)** — How it works under the hood
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — Common issues & fixes
- **[CHANGELOG.md](CHANGELOG.md)** — Version history

---

## Common Tasks

### Check a Site (THE 8 FACTS)
```bash
webdev-migrate inventory portfolios.cs.earlham.edu
```
Shows: domain, server, path, database, environment, multisite status, uploads config, theme/plugins.

### Make a Backup
```bash
webdev-migrate backup /var/www/wordpress-portfolios portfolios live
```
Creates timestamped backup with verification. Shows size estimate first. Auto-cleans old backups.

### Migrate Between Servers
```bash
# Interactive mode (recommended for beginners)
webdev-migrate multi-server

# Or direct command (for pros)
webdev-migrate migrate web:portfolios web-urey:portfolios
```

### Fix Plugin URLs After Migration
```bash
# Standard scan
webdev-migrate url-audit /var/www/site

# Deep scan (checks plugin metadata - for DFlip, galleries, etc.)
webdev-migrate url-audit --deep /var/www/site
```

**[More Examples →](docs/WALKTHROUGHS.md)**

---

## Version History

| Version | Date | Lines | What Changed |
|---------|------|-------|-------------|
| **1.3.0** | Feb 2026 | 5,029 | Multi-server + all DB bugs fixed + size estimation + retention |
| 1.2.1 | Feb 2026 | 3,845 | Beginner UX improvements (site discovery, health checks) |
| 1.2.0 | Feb 2026 | 3,420 | Safety features (locking, validation, dry-run) |
| 1.1.0 | Dec 2025 | 3,007 | Production hardening (earlhamword.com lessons) |
| 1.0.0 | Oct 2025 | 2,340 | Initial unified tool (replaced 5 separate scripts) |

**[Detailed Changelog →](CHANGELOG.md)**

---

## Help

### "I've never done this before"
Start here: **[TRAINING.md](docs/TRAINING.md)**  
It's written for absolute beginners. Takes about an hour. Worth it.

### "Something broke"
Check: **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**  
Common issues with step-by-step solutions.

### "The tool won't let me do something"
That's probably **on purpose**. Read the error message — it explains why and what to do instead.

### "I need to talk to a human"
- **Tool questions:** njalshe23@earlham.edu, @NourTheArab on IG (Nour)
- **Logs:** `/var/log/webdev-migrate/` (check these first!)

```bash
# View recent logs
ls -lt /var/log/webdev-migrate/
tail -100 /var/log/webdev-migrate/webdev-migrate-LATEST.log
```

---

## Contributing

Found a bug? Have an idea?

1. **Check logs first:** `/var/log/webdev-migrate/`
2. **Read troubleshooting:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
3. **Open an issue** on GitLab with logs + steps to reproduce

Want to improve the docs? **YES PLEASE.** Documentation PRs are worth their weight in gold.

---

## A Note to Future Maintainers

Hi future person!

If you're reading this, I've probably graduated and you've inherited this tool, or are interested in the server-side ops of WP. Here's what you should know:

**This tool was built to solve real problems:**
- earlhamword.com multisite migrations (the pain was real)
- DFlip plugin URL issues (serialized data in plugin metadata)
- Testing environment setup (make it match production exactly)
- Training new webdev team members (teach them the right way)

**It's not perfect, but it works.** If something seems weird, there's usually a reason — check the [PHILOSOPHY.md](docs/PHILOSOPHY.md) doc. I tried to explain the "why" behind weird decisions.

**Feel free to improve it!** But please:
- Keep the beginner-friendly approach (future you will thank you)
- Don't break backward compatibility without major version bump
- Update the docs when you change things (seriously, do this)
- Add your own notes to PHILOSOPHY.md (explain your decisions too)

The goal was never "perfect code." The goal was "the next person doesn't suffer like I did."

Good luck! You've got this.

— Nour (Earlham Class of 2027)

---

## License

Made for Earlham College Webdev Team. Use it, improve it, pass it down.

If you use this elsewhere, credit would be nice but not required. Just help the next person like I tried to help you.

---

## Credits

- **Developer:** Nour Al-Sheikh
- **AI Assistant:** NotebookLLM/GPT5.2/Claude/Gemini
- **Testing:** EC Webdev team 
- **v1.1 Driver:** earlhamword.com DFlip debugging hell (never again)
- **v1.2 Design:** Real production experience pain points
- **v1.3 Design:** "Why can't we migrate between servers easily?" frustration

---

## Quick Reference Card

```bash
# SAFETY FIRST
--dry-run                      # Always safe (shows what would happen)

# CORE OPERATIONS
inventory DOMAIN               # Check site (THE 8 FACTS)
backup PATH SLUG ENV           # Create backup
restore BACKUP PATH            # Restore backup
migrate SRC DST                # Move between servers
clone-to-test SLUG             # Create test copy
promote-to-live SLUG           # Deploy test → live

# URL ISSUES
url-audit PATH                 # Standard URL scan
url-audit --deep PATH          # Deep scan (plugin metadata)

# MULTI-SERVER (v1.3)
multi-server                   # Interactive multi-server mode
add-server NAME IP USER        # Add server to session
test-connection NAME           # Test server connection
server-profiles                # List saved servers

# HELP
--help                         # Full command reference
(no arguments)                 # Interactive menu
```

---

**Questions? Start with [QUICKSTART.md](QUICKSTART.md) or [TRAINING.md](docs/TRAINING.md)**

**Need specific examples? Check [WALKTHROUGHS.md](docs/WALKTHROUGHS.md)**

**Want to understand how it works? Read [IMPLEMENTATION.md](docs/IMPLEMENTATION.md)**

**Multi-server questions? See [MULTI-SERVER.md](docs/MULTI-SERVER.md)**
