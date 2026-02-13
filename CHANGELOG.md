# webdev-migrate Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-13

### Added - Safety & Training Features

**Operation Locking (Prevents Concurrent Operations)**
- Added `flock`-based locking system to prevent multiple operations on same site
- Lock acquisition in all major operations (backup, restore, migrate, clone, promote)
- Clear error messages when lock cannot be acquired
- Automatic lock cleanup on exit
- Lock files stored in `/var/lock/webdev-migrate/`

**Dry-Run First (Interactive Mode Safety)**
- Interactive menu now runs dry-run FIRST for destructive operations
- Users see the plan before executing
- Requires explicit "yes" confirmation after seeing dry-run
- Applies to: Option 6 (promote test→live), Option 8 (promote subsite)
- Prevents accidental destructive operations by beginners

**Environment Separation Enforcement**
- New `validate_environment_match()` function
- Validates that "live" points at live paths/databases
- Validates that "test" points at testing paths/databases
- Clear error messages showing what's wrong and what's expected
- Prevents confusion and accidents

**Machine-Readable JSON Output**
- Every inventory now generates `.json` alongside `.txt` report
- Structured data for automation and tool integration
- Contains all 8 FACTS in machine-readable format
- Enables building registry systems and status dashboards

**Deep Scan Decision Tree**
- Added comprehensive guide in `url-audit` explaining when to use `--deep`
- Real-world examples from production (DFlip case)
- Decision flowchart for troubleshooting
- Helps users self-diagnose plugin URL issues

**Serialization Safety Documentation**
- Added critical comments explaining WordPress serialization
- Documents why WP-CLI must be used (not sed/SQL)
- Explains `s:5:"hello"` format and length requirements
- Prevents developers from accidentally breaking databases

### Changed

- **Version**: Bumped to 1.2.0
- **Line count**: 3,420 lines (+413 from v1.1)
- **Lock directory**: Added `/var/lock/webdev-migrate/`
- **Interactive menu**: Now defaults to safer workflow for destructive ops
- **Environment validation**: Now runs automatically in backup/restore/clone operations

### Technical Details

- All major operations now acquire locks: `backup`, `restore`, `clone_live_to_test`, `promote_test_to_live`, `promote_subsite_to_standalone`
- Lock cleanup handled automatically via `cleanup_on_exit` trap
- Environment validation checks both path AND database name for consistency
- JSON output includes all metadata with proper escaping and null handling
- Deep scan guide integrated into tool workflow (not just docs)

### Deployment Notes

**No Breaking Changes**
- Drop-in replacement for v1.1
- Same command syntax
- Same configuration format
- Existing backups remain compatible

**New Requirements**
- `flock` command (standard on most Linux systems)
- Write access to `/var/lock/webdev-migrate/` (auto-created)

**Migration from v1.1**
```bash
sudo cp webdev-migrate /usr/local/bin/
sudo chmod +x /usr/local/bin/webdev-migrate
webdev-migrate --help  # Should show v1.2.0
```

---

## [1.1.0] - 2025-12-01

### Added - Production Hardening

**Multisite Context Detection**
- Automatic blog_id resolution from domain
- Correct table prefix detection (wp_10_* vs wp_*)
- Context-aware WP-CLI flags (`--url=` or `--blog=`)
- Functions: `get_blog_id_for_domain()`, `get_wp_cli_context()`, `get_table_prefix_for_blog()`

**HTTPS Detection Without is_ssl()**
- Three-tier detection: siteurl option → curl test → default HTTPS
- Function: `detect_site_scheme()`
- No longer relies on PHP's is_ssl() which fails in CLI
- Prevents mixed-protocol URLs

**THE 8 FACTS Standardized Output**
- Consistent inventory format for training
- Shows: domain, server, path, database, environment, multisite context, uploads, theme/plugins
- Builds muscle memory for operators
- Saved to timestamped report files

**Restore Verification**
- Automated 6-point verification after restore
- Checks: WordPress core, database integrity, URL options, plugins, uploads, external access
- Clear PASS/FAIL summary
- Catches issues before deployment

**Deep URL Scanning**
- `--deep` flag for scanning plugin metadata
- Finds URLs in serialized data (like `_dflip_data`)
- Reports top 20 meta keys with URLs
- Detects custom post types
- Guided replacement with verification

**Multisite as LEGACY**
- Menu and docs emphasize multisite is being phased out
- Clear recommendation: convert to standalone
- Updated terminology throughout

### Changed

- **Version**: Bumped to 1.1.0
- **Line count**: 3,007 lines (+667 from v1.0)
- All `get_wp_option()` calls now accept domain for multisite context
- Inventory output completely redesigned
- Restore operation now includes verification step

### Fixed

- Wrong table prefix bug in multisite (was querying wp_posts instead of wp_10_posts)
- HTTPS detection failures in WP-CLI context
- Inconsistent inventory output format
- No feedback on restore success/failure
- Plugin URLs in serialized metadata not updated
- Confusing multisite messaging

---

## [1.0.0] - 2025-10-03

### Added - Initial Release

**Core Operations**
- Site inventory with auto-discovery
- Backup creation with manifests
- Restore from backup
- Cross-server migration
- Live→test cloning
- Test→live promotion
- Multisite subsite listing
- Subsite→standalone conversion
- Health checks
- URL audit and fix

**Safety Features**
- Dry-run mode for all operations
- Automatic backups before destructive operations
- Multiple confirmation levels
- Comprehensive logging
- Preflight validation checks

**User Experience**
- Interactive menu for beginners
- Command-line interface for automation
- Color-coded output
- Clear error messages
- Training-focused output

**Documentation**
- README.md - Complete reference
- TRAINING.md - Beginner's guide
- WALKTHROUGHS.md - Step-by-step examples
- QUICKSTART.md - 5-minute start
- IMPLEMENTATION.md - Technical details
- webdev-migrate.conf.example - Configuration template

### Technical Details

- **Line count**: 2,340 lines
- **Architecture**: Single monolithic Bash script
- **Dependencies**: bash, mysql-client, wp-cli, apache2, rsync, ssh, gzip, tar
- **Standard paths**: `/var/www/`, `/srv/backups/wp/`, `/var/log/webdev-migrate/`

---

## Version Comparison

| Feature | v1.0 | v1.1 | v1.2 |
|---------|------|------|------|
| **Line Count** | 2,340 | 3,007 | 3,420 |
| **Operations** | 10 | 10 | 10 |
| **Multisite context** | Basic | Full | Full |
| **HTTPS detection** | is_ssl() | Reliable | Reliable |
| **Inventory format** | Basic | THE 8 FACTS | THE 8 FACTS + JSON |
| **Restore verification** | No | Yes (6-point) | Yes (6-point) |
| **Deep URL scan** | No | Yes | Yes + Guide |
| **Operation locking** | No | No | Yes |
| **Environment validation** | No | No | Yes |
| **Dry-run default** | Optional | Optional | Interactive default |

---

## Upgrade Path

### v1.0 → v1.1
- Drop-in replacement
- No config changes needed
- Immediate benefits from all fixes

### v1.1 → v1.2
- Drop-in replacement
- Lock directory auto-created
- Interactive workflow slightly changed (dry-run first)

### v1.0 → v1.2 (Skip v1.1)
- Fully supported
- All v1.1 + v1.2 features available
- Recommended upgrade path

---

## Credits

- **Primary Developer**: Nour Al-Sheikh (njalshe23@earlham.edu)
- **AI Assistant**: All the AI in the universe at this point. (I left similar easter-eggs around the documentation)
- **Testing & Feedback**: EC Webdev Team
- **Incident That Drove v1.1**: earlhamword.com DFlip migration debugging
- **Safety Features (v1.2)**: Based on production experience and peer feedback

---

## License

Internal tool for Earlham College Computer Science Department.
Not licensed for external distribution.
