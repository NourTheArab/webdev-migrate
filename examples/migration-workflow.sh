#!/usr/bin/env bash
#
# Example Migration Workflow Script
#
# This shows how to automate common migration tasks
# Customize for your needs
#

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

SOURCE_SERVER="web"
DEST_SERVER="web-urey"

# Sites to migrate
SITES=(
    "portfolios"
    "fieldscience"
    "academics"
)

LOG_FILE="/tmp/migration-$(date +%Y%m%d-%H%M%S).log"

# ═══════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ═══════════════════════════════════════════════════════════════
# PRE-FLIGHT CHECKS
# ═══════════════════════════════════════════════════════════════

log "Starting migration workflow"
log "Source: $SOURCE_SERVER"
log "Destination: $DEST_SERVER"
log "Sites: ${SITES[*]}"
log ""

# Test connections
log "Testing server connections..."

if ! webdev-migrate test-connection "$SOURCE_SERVER" >> "$LOG_FILE" 2>&1; then
    log "ERROR: Cannot connect to source server: $SOURCE_SERVER"
    exit 1
fi

if ! webdev-migrate test-connection "$DEST_SERVER" >> "$LOG_FILE" 2>&1; then
    log "ERROR: Cannot connect to destination server: $DEST_SERVER"
    exit 1
fi

log "✓ Server connections verified"
log ""

# ═══════════════════════════════════════════════════════════════
# MIGRATION LOOP
# ═══════════════════════════════════════════════════════════════

SUCCESS_COUNT=0
FAIL_COUNT=0

for site in "${SITES[@]}"; do
    log "════════════════════════════════════════════════════════"
    log "Migrating: $site"
    log "════════════════════════════════════════════════════════"
    
    # Example: Migrate with auto-confirmation (DANGEROUS - use carefully)
    # In production, you'd want manual confirmation
    
    if sudo webdev-migrate migrate "${SOURCE_SERVER}:${site}" "${DEST_SERVER}:${site}" >> "$LOG_FILE" 2>&1; then
        log "✓ SUCCESS: $site migrated"
        ((SUCCESS_COUNT++))
    else
        log "✗ FAILED: $site migration failed"
        ((FAIL_COUNT++))
        
        # Optional: Continue or stop on failure
        # exit 1  # Uncomment to stop on first failure
    fi
    
    log ""
done

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

log "════════════════════════════════════════════════════════"
log "MIGRATION COMPLETE"
log "════════════════════════════════════════════════════════"
log "Successful: $SUCCESS_COUNT"
log "Failed: $FAIL_COUNT"
log "Total: ${#SITES[@]}"
log ""
log "Log file: $LOG_FILE"
log "════════════════════════════════════════════════════════"

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi

exit 0

# ═══════════════════════════════════════════════════════════════
# USAGE EXAMPLES
# ═══════════════════════════════════════════════════════════════
#
# Basic usage:
#   bash migration-workflow.sh
#
# Customize for your needs:
#   1. Edit SITES array above
#   2. Edit SOURCE_SERVER and DEST_SERVER
#   3. Run the script
#
# ═══════════════════════════════════════════════════════════════
# MORE ADVANCED EXAMPLES
# ═══════════════════════════════════════════════════════════════
#
# Example 1: Pre-migration backups
#   for site in "${SITES[@]}"; do
#       log "Creating backup of $site on destination (in case we need to rollback)"
#       sudo webdev-migrate backup "/var/www/wordpress-$site" "$site" "pre-migration"
#   done
#
# Example 2: Post-migration verification
#   for site in "${SITES[@]}"; do
#       log "Running health check on $site"
#       sudo webdev-migrate healthcheck "${site}.cs.earlham.edu"
#   done
#
# Example 3: URL audit after migration
#   for site in "${SITES[@]}"; do
#       log "Auditing URLs in $site"
#       sudo webdev-migrate url-audit --deep "/var/www/wordpress-$site"
#   done
#
# ═══════════════════════════════════════════════════════════════
