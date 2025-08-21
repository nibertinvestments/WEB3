#!/bin/bash

# Backup Management Script for Nibert Investments WEB3 Repository
# Provides utilities for backup creation, validation, and restoration

set -e

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "🔄 Nibert Investments WEB3 - Backup Management"
    echo "================================================"
    echo -e "${NC}"
}

show_help() {
    print_header
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create          Create a local backup"
    echo "  validate        Validate repository integrity"
    echo "  restore [file]  Restore from backup file"
    echo "  list           List available backups"
    echo "  cleanup        Clean old backup files"
    echo "  help           Show this help message"
    echo ""
    echo "Options:"
    echo "  --type [standard|full]  Backup type (default: standard)"
    echo "  --output [path]         Output directory (default: ./backups)"
    echo "  --keep [days]           Days to keep backups (default: 30)"
    echo ""
    echo "Examples:"
    echo "  $0 create --type full"
    echo "  $0 restore backups/nibert-web3-backup-20241220_140000.tar.gz"
    echo "  $0 cleanup --keep 7"
    echo ""
}

validate_repository() {
    log_info "Validating repository integrity..."
    
    # Check critical files
    local critical_files=("server.js" "main.js" "main.py" "package.json" "README.md")
    local missing_files=0
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "$file exists"
        else
            log_error "$file is missing"
            ((missing_files++))
        fi
    done
    
    # Validate Node.js syntax
    if [ -f "server.js" ]; then
        if node -c server.js 2>/dev/null; then
            log_success "Node.js server syntax is valid"
        else
            log_error "Node.js server syntax validation failed"
            ((missing_files++))
        fi
    fi
    
    # Check smart contracts
    if [ -d "contracts" ]; then
        local contract_count=$(find contracts -name "*.sol" | wc -l)
        log_success "Found $contract_count smart contracts"
    else
        log_warning "Smart contracts directory not found"
    fi
    
    # Check package.json integrity
    if [ -f "package.json" ]; then
        if python3 -c "import json; json.load(open('package.json'))" 2>/dev/null; then
            log_success "package.json is valid JSON"
        else
            log_error "package.json is invalid JSON"
            ((missing_files++))
        fi
    fi
    
    if [ $missing_files -eq 0 ]; then
        log_success "Repository validation completed successfully"
        return 0
    else
        log_error "Repository validation failed with $missing_files issues"
        return 1
    fi
}

create_backup() {
    local backup_type="standard"
    local output_dir="$BACKUP_DIR"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                backup_type="$2"
                shift 2
                ;;
            --output)
                output_dir="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    print_header
    log_info "Creating $backup_type backup..."
    
    # Validate before backup
    if ! validate_repository; then
        log_error "Pre-backup validation failed. Aborting backup creation."
        exit 1
    fi
    
    # Create backup directory
    mkdir -p "$output_dir"
    
    # Create backup filename
    local backup_file="$output_dir/nibert-web3-backup-$TIMESTAMP.tar.gz"
    local metadata_file="$output_dir/backup-metadata-$TIMESTAMP.json"
    
    # Create backup
    log_info "Creating backup archive..."
    
    if [ "$backup_type" = "full" ]; then
        tar -czf "$backup_file" \
            --exclude='.git' \
            --exclude='node_modules' \
            --exclude='*.log' \
            --exclude='.DS_Store' \
            --exclude='backups' \
            .
    else
        tar -czf "$backup_file" \
            --exclude='.git' \
            --exclude='node_modules' \
            --exclude='*.log' \
            --exclude='.DS_Store' \
            --exclude='backups' \
            --exclude='*.tmp' \
            --exclude='coverage' \
            .
    fi
    
    # Create metadata
    cat > "$metadata_file" << EOF
{
  "backup_date": "$DATE",
  "backup_timestamp": "$TIMESTAMP",
  "backup_type": "$backup_type",
  "repository_path": "$(pwd)",
  "backup_file": "$backup_file",
  "file_size": "$(du -h "$backup_file" | cut -f1)",
  "created_by": "backup-management-script",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'not-a-git-repo')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'not-a-git-repo')"
}
EOF
    
    # Display results
    local file_size=$(du -h "$backup_file" | cut -f1)
    log_success "Backup created successfully!"
    echo ""
    echo "📋 Backup Details:"
    echo "  📁 File: $backup_file"
    echo "  📊 Size: $file_size"
    echo "  🏷️  Type: $backup_type"
    echo "  📅 Date: $DATE"
    echo "  🕒 Time: $TIMESTAMP"
    echo ""
    log_info "Metadata saved to: $metadata_file"
}

list_backups() {
    print_header
    log_info "Available backups in $BACKUP_DIR:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_warning "No backups found in $BACKUP_DIR"
        return
    fi
    
    # List backup files with details
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup" ]; then
            local filename=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S")
            echo "📦 $filename"
            echo "   📊 Size: $size"
            echo "   📅 Modified: $date"
            echo ""
        fi
    done
}

cleanup_backups() {
    local keep_days=30
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --keep)
                keep_days="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    print_header
    log_info "Cleaning up backups older than $keep_days days..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        log_warning "Backup directory $BACKUP_DIR does not exist"
        return
    fi
    
    local deleted_count=0
    
    # Find and delete old backups
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        log_info "Deleting old backup: $filename"
        rm "$file"
        ((deleted_count++))
        
        # Also delete corresponding metadata
        local metadata="${file%.tar.gz}"
        metadata="${metadata/backup-/backup-metadata-}.json"
        if [ -f "$metadata" ]; then
            rm "$metadata"
        fi
    done < <(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$keep_days -print0)
    
    if [ $deleted_count -eq 0 ]; then
        log_success "No old backups to clean up"
    else
        log_success "Deleted $deleted_count old backup(s)"
    fi
}

restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_error "Please specify a backup file to restore"
        echo "Usage: $0 restore [backup_file]"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_header
    log_warning "WARNING: This will restore the repository from backup"
    log_warning "Current files may be overwritten!"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore operation cancelled"
        return 0
    fi
    
    log_info "Restoring from backup: $(basename "$backup_file")"
    
    # Create backup of current state
    local current_backup="./current-state-backup-$TIMESTAMP.tar.gz"
    log_info "Creating backup of current state: $current_backup"
    tar -czf "$current_backup" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='*.log' \
        --exclude='.DS_Store' \
        --exclude='backups' \
        . 2>/dev/null || log_warning "Could not backup current state"
    
    # Extract backup
    log_info "Extracting backup..."
    tar -xzf "$backup_file"
    
    # Validate restoration
    log_info "Validating restored repository..."
    if validate_repository; then
        log_success "Repository restored successfully!"
        log_info "Current state backup saved as: $current_backup"
    else
        log_error "Restoration validation failed"
        return 1
    fi
}

# Main script logic
case "${1:-help}" in
    create)
        shift
        create_backup "$@"
        ;;
    validate)
        print_header
        validate_repository
        ;;
    restore)
        shift
        restore_backup "$@"
        ;;
    list)
        list_backups
        ;;
    cleanup)
        shift
        cleanup_backups "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac