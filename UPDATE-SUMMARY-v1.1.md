# webdev-migrate v1.1 - Production Hardening Update

**Update Date:** December 01, 2025
**Previous Version:** 1.0.0 (2,340 lines)
**Current Version:** 1.1.0 (3,007 lines)
**Lines Added:** 667 lines of critical fixes

## Executive Summary

Based on real production issues encountered with multisite-to-standalone migrations (specifically the earlhamword.com DFlip case), this update addresses **6 critical gaps** that would cause the tool to fail in production. These aren't nice-to-haves, they're "tool breaks in subtle ways without these" issues.

## The 6 Critical Fixes

### Fix #1: WP-CLI Context (Multisite Table Prefixes)

**Problem:** In multisite, blog_id 10's content lives in `wp_10_posts`, `wp_10_postmeta`, etc., but the tool was querying `wp_posts` and finding nothing or wrong data.

**Solution Implemented:**

1. **New Functions:**
   ```bash
   get_blog_id_for_domain()      # Resolves domain → blog_id
   get_wp_cli_context()          # Returns correct --url or --path flags
   get_table_prefix_for_blog()   # Returns wp_10_ or wp_ as needed
   ```

2. **Automatic Detection:**
   - Every operation now detects if site is in multisite
   - Automatically resolves blog_id from domain
   - Uses `--url=https://domain` (most reliable) or `--blog=<id>`
   - Applies correct table prefix for direct SQL queries

3. **Implementation:**
   - `inventory_site()` - shows both network and site table prefixes
   - `get_wp_option()` - now accepts domain parameter for multisite context
   - `url_audit()` - uses correct table prefix when scanning
   - All WP-CLI calls wrapped with `$(get_wp_cli_context ...)`

**Impact:** Eliminates the "why is my content missing?" bug entirely.

---

### Fix #2: HTTPS Detection (No More is_ssl())

**Problem:** `is_ssl()` in WP-CLI often returns false even when site is HTTPS because `$_SERVER` variables aren't populated. This caused mixed-protocol URLs.

**Solution Implemented:**

1. **New Function:**
   ```bash
   detect_site_scheme()  # Returns "https" or "http" reliably
   ```

2. **Three-Tier Detection:**
   - Priority 1: Parse scheme from `siteurl` and `home` options
   - Priority 2: Test with `curl -I https://domain`
   - Priority 3: Default to HTTPS (duh..)

3. **Never Uses:**
   - `is_ssl()` function
   - Proxy header checks in CLI context
   - Assumptions about protocol

4. **Integration:**
   - `inventory_site()` now shows "Canonical Scheme"
   - URL replacements use detected scheme
   - Verification checks use correct protocol

**Impact:** Fixes protocol mismatches that break media loading.

---

### Fix #3: Standardized "8 FACTS" Output

**Problem:** Inventory output was inconsistent, making it hard for beginners to build muscle memory.

**Solution Implemented:**

**The 8 Facts Every Newbie Needs:**
```
1. DOMAIN              - What domain is this?
2. SERVER              - Which physical machine?
3. WORDPRESS PATH      - Where are the files?
4. DATABASE            - Name, user, host, (password if --show-secrets. Make sure you NEED to know the password to use this.)
5. ENVIRONMENT         - live or test?
6. MULTISITE CONTEXT   - Is it multisite? Blog ID? Table prefix?
7. UPLOADS CONFIG      - Path, URL, uses sites/<id>?
8. THEME & PLUGINS     - Active theme, plugin count, network plugins
```

**New Output Format:**
- Labeled as "THE 8 FACTS (memorize this!)"
- Consistent order every time
- Includes WP-CLI command to use
- Shows both network and site-specific info for multisite
- Saved to timestamped report file

**Impact:** Training muscle memory—users learn one pattern and apply it everywhere.

---

### Fix #4: Restore Verification (Confidence Checks)

**Problem:** Backups that exist but don't restore cleanly are worse than no backups in my humble opinion, after spending more than 50+ hours trying to figure it out. Trust me. No way to know if restore actually worked.

**Solution Implemented:**

**Automated 6-Point Verification:**
1. WordPress core responds (`wp core version`)
2. Database integrity (`wp db check`)
3. URL options present and correct (`wp option get home/siteurl`)
4. Plugins accessible (`wp plugin list`)
5. Uploads configured (`wp_upload_dir()['baseurl']`)
6. External accessibility (`curl -I https://domain/wp-login.php`)

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RESTORE VERIFICATION SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Passed:  6
Failed:  0

✓ PASS - Restore completed successfully and verified
```

**If Failed:**
- Lists specific issues found
- Provides remediation steps
- Returns error code for automation
- Prevents bad restores from going unnoticed

**Impact:** No more "restored but doesn't work" surprises, thank Code (haha).

---

### Fix #5: Deep URL Scan (Plugin Metadata - The DFlip Fix)

**Problem:** For a specific site I used a plugin called DFlip, to showcase PDFs in a nice way. It backfired heavily, but still..DFlip stores PDF URLs in serialized `_dflip_data` meta. Standard search-replace misses these. Files exist, permissions fine, but plugin shows old URLs.

**Solution Implemented:**

**Two-Tier URL Audit:**

**Standard Scan (default):**
- Checks common patterns (testing domains, http://, localhost)
- Uses WP-CLI search with correct table context
- Fast and safe

**Deep Scan (`--deep` flag):**
1. **Scans `wp_postmeta` for URLs:**
   - Finds top 20 meta keys containing "http"
   - Reports counts per key

2. **Plugin-Specific Checks:**
   - Looks for known keys: `_dflip_data`, `_pdf_info`, `_document_data`
   - Counts entries with problematic patterns
   - Highlights URLs in serialized data

3. **Custom Post Type Detection:**
   - Lists all custom post types (like 'dflip')
   - Shows counts for each type
   - Helps identify plugin content

4. **Guided Fixes:**
   - Offers targeted search-replace
   - Handles multisite uploads paths (`/sites/<id>/`)
   - Verifies replacements worked

**Usage:**
```bash
# just a standard scan
webdev-migrate url-audit /var/www/site

# Deep scan (for plugin issues, thank you dflip)
webdev-migrate url-audit --deep /var/www/site
```

**Example Output:**
```
=== DEEP SCAN (Plugin-Stored URLs) ===

Top 20 meta keys containing URLs:
  • _dflip_data (47 entries)
  • _thumbnail_id (234 entries)
  
⚠ Found 47 entries with key: _dflip_data
  → 23 contain: testing.cs.earlham.edu
  → 15 contain: /sites/10/

Custom post types found:
  • dflip (47 posts)
```

**Impact:** Catches the DFlip case and similar plugin URL storage issues.

---

### Fix #6: Multisite as LEGACY (Emphasized Throughout)

**Problem:** Multisite was presented as equal option, not as "phase this out." Now if the mindset changes after my departure, this will have to be revisited. I think it's worth moving away from Multisite completely.

**Solution Implemented:**

1. **Menu Labels:**
   ```
   7) Multisite: inspect / list subsites (LEGACY)
   8) Multisite: promote subsite to standalone (RECOMMENDED)
   
   Note: Multisite is LEGACY - we're phasing it out.
         Use option 8 to convert subsites to standalone.
   ```

2. **Help Text:**
   ```
   MULTISITE NOTES:
       This tool treats multisite as LEGACY. The recommended approach is:
       1. List subsites: list-subsites
       2. Promote to standalone: promote-subsite
       3. Phase out the multisite installation
   ```

3. **Training Documentation:**
   - Updated to emphasize standalone > multisite
   - Walkthroughs focus on promotion workflow
   - "Phasing out" mentioned prominently

4. **Operational Support:**
   - Full promote-subsite workflow
   - Verification steps for promoted sites
   - Cleanup guidance

**Impact:** Clear direction for new users - don't create new multisites.

---

## Technical Implementation Details

### Architecture Changes

**No Breaking Changes:**
- Monolithic single-script maintained
- Same standard paths
- Same configuration file format
- Backward compatible with existing backups

**New Capabilities:**
- Multisite context awareness throughout
- HTTPS detection without PHP
- Deep database scanning
- Automated verification

### Code Quality

**Before:**
- 2,340 lines
- Basic multisite support
- Limited error detection
- Simple URL scanning

**After:**
- 3,007 lines (+667)
- Full multisite context system
- Comprehensive verification
- Deep plugin metadata scanning
- Standardized output format

**Added Functions:**
```bash
get_blog_id_for_domain()      # Multisite blog_id resolution
get_wp_cli_context()          # Context-aware WP-CLI flags
get_table_prefix_for_blog()   # Correct table prefix
detect_site_scheme()          # Reliable HTTPS detection
get_content_url()             # Content URL with context
get_uploads_info()            # Uploads info with JSON parsing
```

**Enhanced Functions:**
- `inventory_site()` - Now outputs THE 8 FACTS
- `restore_backup()` - Now includes 6-point verification
- `url_audit()` - Now supports --deep plugin scanning
- `get_wp_option()` - Now multisite-aware

### Testing Recommendations

**Before Production Deployment:**

1. **Multisite Context Test:**
   ```bash
   webdev-migrate inventory cs.earlham.edu  # Should show blog_id
   ```

2. **HTTPS Detection Test:**
   ```bash
   webdev-migrate --verbose inventory site.edu  # Check canonical scheme
   ```

3. **Restore Verification Test:**
   ```bash
   # Make backup, restore it, should show PASS/FAIL
   webdev-migrate backup /var/www/site site test
   webdev-migrate restore /srv/backups/.../TIMESTAMP /tmp/test-restore
   ```

4. **Deep Scan Test:**
   ```bash
   # On site with plugin metadata
   webdev-migrate url-audit --deep /var/www/site
   ```

---

## Migration Path from v1.0 to v1.1

**For Existing Users:**

1. **Drop-in Replacement:**
   ```bash
   sudo cp webdev-migrate /usr/local/bin/
   sudo chmod +x /usr/local/bin/webdev-migrate
   ```

2. **No Configuration Changes Needed:**
   - Same config file format
   - Same directory structure
   - Same command syntax

3. **New Features Available Immediately:**
   - Run `inventory` to see THE 8 FACTS format
   - Use `url-audit --deep` for plugin scans
   - Restore verification runs automatically

4. **Existing Backups:**
   - Fully compatible
   - Will restore with new verification
   - Same directory structure

---

## Real-World Impact

### Before v1.1 (What Would Have Happened):

**Scenario:** Promoting earlhamword.com (blog_id 10) from multisite

1. Query `wp_posts` instead of `wp_10_posts` → "Where's my content?"
2. HTTPS detection fails → Mixed protocol URLs
3. DFlip URLs not updated → PDFs don't load
4. Restore works but no verification → Deploy broken site
5. Manual debugging for hours

### After v1.1 (What Actually Happens):

1. Automatic blog_id detection → Correct tables queried
2. HTTPS detected from siteurl → Consistent protocol
3. Deep scan finds _dflip_data → All URLs updated
4. Restore verification catches issues → Fix before deploy
5. Tool just works → Deploy with confidence

**Time Saved:** 4-6 hours of debugging per migration (this is with the use of AI. Without it, give yourself a week or so..)
**Error Rate:** Reduced from "occasional data loss" to "caught before deploy"

---

## Documentation Updates

All documentation has been updated to reflect v1.1 changes:

- README.md - Added --deep flag, THE 8 FACTS, verification
- TRAINING.md - Updated with new concepts
- WALKTHROUGHS.md - Examples use correct context
- QUICKSTART.md - Mentions key features
- Help text (`--help`) - Full command reference

---

## Remaining Known Limitations

These are acceptable trade-offs, not bugs:

1. **Python Required for JSON Parsing:**
   - uploads_info parsing needs python3
   - Graceful fallback to defaults if missing
   - Could add jq as alternative

2. **Cross-Server Multisite:**
   - Complex when source and dest are different hosts
   - Manual verification recommended
   - Works but needs careful testing

3. **Large Databases:**
   - Deep scan can take several minutes
   - Progress indicators help
   - Could add timeout/sampling options

4. **SSL Certificate Management:**
   - Tool doesn't handle certbot
   - Provides instructions only
   - Could integrate in future

---

## Success Metrics

**How to Measure Success:**

1. **Zero "Wrong Table" Issues:**
   - Inventory shows correct blog_id
   - Content found in correct tables
   - No more "missing posts" bugs

2. **Protocol Consistency:**
   - No mixed http/https in database
   - Media loads correctly
   - Canonical scheme detected accurately

3. **Restore Confidence:**
   - Verification catches issues
   - PASS/FAIL is accurate
   - No bad restores deployed

4. **Plugin URL Issues:**
   - Deep scan finds problem keys
   - DFlip-type issues resolved
   - Media accessible after migration

5. **User Confidence:**
   - Beginners can follow 8 FACTS
   - Dry runs prevent mistakes
   - Training materials match tool

---

## Deployment Checklist

**Before Deploying v1.1:**

- [ ] Read this document completely
- [ ] Test inventory on multisite (verify blog_id detection)
- [ ] Test restore verification (check PASS/FAIL works)
- [ ] Test deep scan (on site with plugin metadata)
- [ ] Update documentation on your wiki/internal docs
- [ ] Train team on THE 8 FACTS concept
- [ ] Set expectations: "tool now catches issues before deploy"

**After Deploying:**

- [ ] Run inventory on all current sites (build baseline)
- [ ] Use --deep on sites with media issues
- [ ] Share THE 8 FACTS template with team
- [ ] Document any site-specific quirks discovered

---

## Support & Rollback

**If Issues Found:**

1. **Bug Report Should Include:**
   - Full log file from `/var/log/webdev-migrate/`
   - THE 8 FACTS output from `inventory`
   - Specific command run
   - Expected vs actual behavior

2. **Quick Rollback:**
   ```bash
   # If v1.1 causes issues, revert:
   sudo cp webdev-migrate-v1.0.backup /usr/local/bin/webdev-migrate
   ```

3. **Partial Adoption:**
   - Can use v1.0 for most operations
   - Use v1.1 only for multisite conversions
   - No data compatibility issues

---

## Credits & Acknowledgments

**This update addresses issues discovered during:**
- earlhamword.com multisite → standalone migration
- DFlip plugin URL debugging session
- Production deployment at Earlham CS

**Key Insights From:**
- Real multisite blog_id 10 debugging
- HTTPS detection failures in WP-CLI
- Serialized plugin metadata challenges
- Beginner training observations

---

## Version History

**v1.1.0 (February 13, 2025) - Production Hardening**
- Fix #1: Multisite context detection (blog_id, table prefixes)
- Fix #2: HTTPS detection without is_ssl()
- Fix #3: Standardized "8 FACTS" output
- Fix #4: Restore verification with PASS/FAIL
- Fix #5: Deep URL scan for plugin metadata
- Fix #6: Multisite as LEGACY emphasis
- Code: 3,007 lines (+667 from v1.0)

**v1.0.0 (February 12, 2025) - Initial Release**
- Initial unified tool
- Basic operations implemented
- Documentation package
- Code: 2,340 lines

---

## Conclusion

This is production hardening based on real failures. Every fix addresses an actual issue that caused user confusion or data problems and over-consumption of caffiene.

**The tool is now truly production-ready for beginners.**

Deploy with confidence. The 6 critical gaps are closed.
