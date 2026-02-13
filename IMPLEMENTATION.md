# webdev-migrate Implementation Summary

## Overview

This document summarizes the unified WordPress migration tool created to consolidate and improve upon our existing scripts. 

## What Was Built

### Main Tool: `webdev-migrate`

A single, comprehensive Bash script (3,000+ lines) that unifies all WordPress management operations with:

- **Interactive menu system** for beginners
- **Command-line interface** for automation and advanced users
- **10 major operations** covering all migration scenarios
- **Comprehensive safety features** including dry-run, backups, and confirmations
- **Detailed logging** with timestamped files
- **Discovery capabilities** to automatically find WordPress installations
- **Remote execution support** for cross-server operations

## Features Implemented

### Core Operations

1. **Inventory** - Discover and document WordPress installations
   - Auto-discovers WordPress path from domain
   - Shows all configuration details
   - Validates installation health
   - Outputs human-readable reports

2. **Backup** - Create consistent, restorable backups
   - Database dump (with single-transaction for consistency)
   - Uploads archive
   - Configuration files
   - Plugin/theme lists
   - Manifest with metadata
   - Auto-generated restore helper script

3. **Restore** - Restore from backup
   - Validates backup integrity
   - Creates target database
   - Imports all data
   - Sets correct permissions
   - Provides next steps guidance

4. **Migrate** - Full site migration between servers
   - Creates backup on source
   - Transfers securely via rsync
   - Restores on destination
   - Updates URLs automatically
   - Handles cross-server operations
   - Provides Apache configuration instructions

5. **Clone Live→Test** - Create testing environments
   - Copies database with new name
   - Syncs all files
   - Updates URLs to test subdomain
   - Adds robots.txt to prevent indexing
   - Keeps live site untouched

6. **Promote Test→Live** - Deploy tested changes
   - Requires explicit confirmation (type "PROMOTE-SITENAME")
   - Creates safety backup first
   - Replaces live with test
   - Updates URLs back to live
   - Shows rollback instructions

7. **List Multisite Subsites** - Inspect multisite installations
   - Lists all subsites with blog IDs
   - Shows domains and paths
   - Uses WP-CLI for accuracy

8. **Promote Subsite to Standalone** - Convert multisite to single-site
   - Exports blog-specific tables
   - Converts table prefixes (wp_10_* → wp_*)
   - Copies users/usermeta
   - Moves uploads from sites/ID/ to uploads/
   - Removes multisite constants
   - Creates clean wp-config.php
   - Updates all URLs

9. **Health Check** - Comprehensive diagnostics
   - WordPress files validation
   - Database connectivity test
   - URL configuration check
   - Apache vhost verification
   - File permissions audit
   - Site accessibility test
   - Error log review

10. **URL Audit** - Find and fix URL issues
    - Scans entire database for URL patterns
    - Detects testing URLs in live sites
    - Automated search-replace with WP-CLI
    - Handles serialized data safely

### Safety Features

1. **Dry Run Mode** (`--dry-run`)
   - Shows what would happen without executing
   - Perfect for learning and planning
   - No risk to live data

2. **Verbose Mode** (`--verbose`)
   - Detailed debug output
   - Helps troubleshoot issues
   - Educational for learning operations

3. **Confirmation Prompts**
   - Multiple levels for dangerous operations
   - Explicit confirmation strings for critical operations
   - Can be bypassed with `--assume-yes` for automation

4. **Automatic Backups**
   - Creates backups before destructive changes
   - Promotion creates "pre-promotion" backup
   - Multisite conversions backup entire multisite first

5. **Comprehensive Logging**
   - Every run creates timestamped log file
   - All operations logged with context
   - Logs persisted to `/var/log/webdev-migrate/`
   - Both stdout and stderr captured

6. **Validation**
   - Preflight checks for requirements
   - WordPress installation validation
   - Database connection testing
   - Disk space verification
   - Permission checks

7. **Error Handling**
   - Strict error mode (`set -euo pipefail`)
   - Graceful error messages
   - Exit codes for automation
   - Cleanup on exit

### User Experience Features

1. **Interactive Menu**
   - Clear, numbered options
   - Beginner-friendly language
   - Guided prompts with defaults
   - Resume/continue pattern

2. **Smart Discovery**
   - Auto-finds WordPress from domain
   - Searches Apache configs
   - Tries standard locations
   - Falls back to manual entry

3. **Clear Output**
   - Color-coded messages (when TTY)
   - Section headers for organization
   - Progress indicators
   - Success/warning/error distinction

4. **Training Output**
   - Every operation explains what it did
   - Shows where files are located
   - Provides next steps
   - Includes troubleshooting hints

5. **Context-Aware Help**
   - Inline help during operations
   - Suggests fixes for common issues
   - Points to documentation
   - Shows example commands

## Documentation Package

### 1. README.md (Comprehensive Reference)
- Complete feature documentation
- All commands with examples
- Configuration guide
- Common workflows
- Troubleshooting section
- Directory structure
- Safety features explained

### 2. TRAINING.md (Beginner's Guide)
- Explains basic concepts (WordPress, servers, databases)
- Step-by-step instructions for new users
- Practice exercises
- Glossary of terms
- Emergency procedures
- Quick reference card
- Designed for staff with zero web dev experience

### 3. WALKTHROUGHS.md (Detailed Examples)
- Three golden path scenarios:
  1. Migrate site web→web-urey (complete with all steps)
  2. Clone live→test workflow
  3. Multisite to standalone conversion
- Each with phases, steps, and verification
- Includes time estimates
- Shows expected output
- Troubleshooting for common issues

### 4. QUICKSTART.md (5-Minute Start)
- Minimal quick start guide
- Installation one-liner
- Most common commands
- Where to find more help

### 5. webdev-migrate.conf.example
- Complete configuration template
- Commented with explanations
- Shows all available options
- Environment-specific examples

## Improvements Over Original Scripts

### vs. export-script.sh
- Works with all sites (not just hardcoded list)
- Better error handling
- Progress indicators
- Manifest generation
- Restore helper script
- Validation before/after

### vs. backups_to_live.sh
- Interactive with confirmations
- Validates backup integrity
- Better permission handling
- URL updating included
- Health checks after restore
- Clear success/failure indication

### vs. create_new_site.sh
- Part of inventory and migration workflows
- Better input validation
- Handles edge cases
- Creates proper backups
- Verifies creation success

### vs. delete_site.sh
- Can be added as operation if needed
- Backup before deletion
- Comprehensive cleanup
- Verification steps

### vs. live_to_test.sh
- Integrated clone-to-test operation
- Handles robots.txt automatically
- Validates both endpoints
- Clear next steps
- Works with any site

### vs. ms-to-sa.sh
- More robust table conversion
- Better error handling
- Validates multisite first
- Handles uploads properly
- Clean wp-config generation
- Post-conversion verification

## Technical Implementation Details

### Architecture
- Single monolithic script (easier to deploy/manage)
- Functional design with clear separation
- Global configuration with overrides
- Remote execution abstraction layer
- State management via log files

### Dependencies
- Bash 4.0+
- Standard GNU utilities (sed, awk, grep, find, tar)
- MySQL client tools
- WP-CLI (required)
- Apache tools (apache2ctl, a2ensite, etc.)
- rsync for file operations
- SSH for remote operations

### Configuration
- Config file: `~/.webdev-migrate.conf`
- Environment variables respected
- Command-line flags override everything
- Sensible defaults for Earlham environment

### Standards Followed
- WordPress path: `/var/www/wordpress-{slug}`
- Test path: `/var/www/wordpress-testing-{slug}`
- Database: `wp_{slug}` or `wp_testing_{slug}`
- Backups: `/srv/backups/wp/{slug}/{env}/{timestamp}/`
- Logs: `/var/log/webdev-migrate/`
- Apache configs: `/etc/apache2/sites-available/`

## Deployment Instructions

### Step 1: Copy Script to Server

```bash
# On web-urey (or any server)
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate
```

### Step 2: Install Dependencies

```bash
sudo apt update
sudo apt install -y \
    mysql-client \
    wordpress-cli \
    apache2 \
    rsync \
    openssh-client \
    gzip \
    tar \
    coreutils \
    findutils \
    gawk \
    sed \
    grep
```

### Step 3: Create Directories

```bash
# Backup directory
sudo mkdir -p /srv/backups/wp
sudo chown -R www-data:www-data /srv/backups/wp
sudo chmod -R 755 /srv/backups/wp

# Log directory
sudo mkdir -p /var/log/webdev-migrate
sudo chmod 777 /var/log/webdev-migrate  # Or chown to operators
```

### Step 4: Copy Documentation

```bash
sudo mkdir -p /usr/local/share/doc/webdev-migrate
sudo cp README.md TRAINING.md WALKTHROUGHS.md QUICKSTART.md \
    /usr/local/share/doc/webdev-migrate/
```

### Step 5: Create Config (Optional)

```bash
cp webdev-migrate.conf.example ~/.webdev-migrate.conf
# Edit as needed
nano ~/.webdev-migrate.conf
```

### Step 6: Test Installation

```bash
# Should show help
webdev-migrate --help

# Should show version and start menu
webdev-migrate

# Test with dry run
webdev-migrate --dry-run inventory portfolios.cs.earlham.edu
```

## Usage Examples

### For Beginners

Just run the script and use the menu:
```bash
webdev-migrate
```

### For Daily Operations

```bash
# Quick health check
webdev-migrate healthcheck portfolios.cs.earlham.edu

# Daily backup
webdev-migrate backup /var/www/wordpress-portfolios portfolios live

# Check for URL issues
webdev-migrate url-audit /var/www/wordpress-portfolios
```

### For Migrations

```bash
# Plan migration
webdev-migrate --dry-run migrate web:site web-urey:site

# Execute migration
webdev-migrate migrate web:site web-urey:site

# Verify
webdev-migrate healthcheck site.cs.earlham.edu web-urey
```

### For Automation

```bash
# Backup all sites nightly
for site in portfolios hop fieldscience; do
    webdev-migrate --non-interactive --assume-yes \
        backup "/var/www/wordpress-$site" "$site" live
done
```

## Maintenance

### Log Rotation

Add to `/etc/logrotate.d/webdev-migrate`:
```
/var/log/webdev-migrate/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
}
```

### Backup Cleanup

Add to cron (monthly):
```bash
# Remove backups older than 90 days
find /srv/backups/wp -type d -name "20*" -mtime +90 -exec rm -rf {} \;
```

### Updates

When updating the script:
```bash
sudo cp new-webdev-migrate /usr/local/bin/webdev-migrate
sudo chmod +x /usr/local/bin/webdev-migrate
webdev-migrate --help  # Verify new version
```