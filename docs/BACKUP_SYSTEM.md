# 🔄 Backup System Documentation

## Overview

The Nibert Investments WEB3 repository includes a comprehensive backup system to protect against data loss and ensure business continuity. The system provides both automated daily backups and manual backup management tools.

## 🤖 Automated Daily Backups

### GitHub Actions Workflow

The repository automatically creates daily backups using GitHub Actions:

- **Schedule**: Daily at 2:00 AM UTC
- **Retention**: 90 days
- **Storage**: GitHub Actions Artifacts
- **Validation**: Pre-backup integrity checks

#### Manual Trigger

You can manually trigger a backup:

1. Go to **Actions** tab in GitHub
2. Select **Daily Backup** workflow
3. Click **Run workflow**
4. Choose backup type:
   - `standard`: Regular backup (default)
   - `full`: Complete backup with all files
   - `release`: Creates a GitHub release with backup

### Accessing Automated Backups

1. Navigate to **Actions** tab in GitHub
2. Click on a **Daily Backup** workflow run
3. Download artifacts from the **Artifacts** section
4. Extract the `.tar.gz` file to restore

## 🛠️ Manual Backup Management

### Backup Script

Use the `scripts/backup-manager.sh` script for local backup operations:

```bash
# Make script executable (one-time setup)
chmod +x scripts/backup-manager.sh

# Show help
./scripts/backup-manager.sh help
```

### Commands

#### Create Backup
```bash
# Standard backup
./scripts/backup-manager.sh create

# Full backup with all files
./scripts/backup-manager.sh create --type full

# Custom output directory
./scripts/backup-manager.sh create --output /path/to/backups
```

#### List Backups
```bash
./scripts/backup-manager.sh list
```

#### Validate Repository
```bash
./scripts/backup-manager.sh validate
```

#### Restore from Backup
```bash
./scripts/backup-manager.sh restore backups/nibert-web3-backup-YYYYMMDD_HHMMSS.tar.gz
```

#### Cleanup Old Backups
```bash
# Remove backups older than 30 days (default)
./scripts/backup-manager.sh cleanup

# Remove backups older than 7 days
./scripts/backup-manager.sh cleanup --keep 7
```

## 📦 Backup Contents

### Included Files
- ✅ All source code (`*.js`, `*.py`, `*.sol`)
- ✅ Configuration files (`package.json`, etc.)
- ✅ Documentation (`*.md`)
- ✅ Smart contracts (complete `/contracts` directory)
- ✅ GitHub Actions workflows (`.github/`)
- ✅ License and legal files

### Excluded Files
- ❌ `.git` directory (Git history)
- ❌ `node_modules` (NPM dependencies)
- ❌ Log files (`*.log`)
- ❌ Temporary files (`*.tmp`, `.DS_Store`)
- ❌ Build artifacts (`coverage/`, `dist/`)

## 🔍 Backup Validation

Each backup includes automatic validation:

### Pre-Backup Checks
- **File Integrity**: Validates critical files exist
- **Syntax Validation**: Checks Node.js server syntax
- **JSON Validation**: Validates `package.json` structure
- **Smart Contracts**: Counts and verifies contract files

### Post-Restore Validation
- **Repository Structure**: Ensures all critical files restored
- **Functionality Test**: Validates core functionality works
- **Dependencies**: Checks package configurations

## 📋 Backup Metadata

Each backup includes metadata file with:

```json
{
  "backup_date": "2024-12-20",
  "backup_timestamp": "20241220_140000",
  "backup_type": "standard",
  "repository_path": "/path/to/repo",
  "backup_file": "nibert-web3-backup-20241220_140000.tar.gz",
  "file_size": "56K",
  "created_by": "backup-management-script",
  "git_commit": "abc123def456",
  "git_branch": "main"
}
```

## 🚨 Emergency Restore Procedures

### Quick Restore from GitHub Actions

1. **Download Latest Backup**:
   - Go to GitHub Actions → Daily Backup
   - Download latest successful backup artifact
   - Extract to temporary location

2. **Restore Critical Files**:
   ```bash
   # Extract backup
   tar -xzf nibert-web3-backup-YYYYMMDD_HHMMSS.tar.gz
   
   # Validate extraction
   ls -la
   
   # Test functionality
   npm install
   node -c server.js
   npm start
   ```

### Local Restore

```bash
# Option 1: Use backup script
./scripts/backup-manager.sh restore backups/backup-file.tar.gz

# Option 2: Manual extraction
tar -xzf backups/backup-file.tar.gz
npm install
npm start
```

## 🔒 Security Considerations

### Backup Security
- **No Secrets**: Backups exclude sensitive data and credentials
- **Access Control**: GitHub Actions artifacts require repository access
- **Encryption**: Consider encrypting sensitive backups for off-site storage

### Best Practices
- **Regular Testing**: Periodically test backup restoration
- **Multiple Locations**: Store important backups in multiple locations
- **Version Control**: Git provides additional backup through distributed nature
- **Documentation**: Keep backup procedures documented and updated

## 📊 Monitoring and Alerts

### Backup Status Monitoring
- **GitHub Actions**: Monitor workflow success/failure
- **Artifact Retention**: Track backup retention periods
- **Storage Usage**: Monitor artifact storage consumption

### Failure Notifications
- GitHub automatically sends notifications for failed workflows
- Check Actions tab regularly for backup status
- Set up custom notifications if needed

## ⚙️ Configuration

### Backup Schedule
Edit `.github/workflows/daily-backup.yml`:
```yaml
schedule:
  - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

### Retention Period
Modify retention in workflow:
```yaml
retention-days: 90  # Change as needed
```

### Exclusion Patterns
Update backup script exclusions:
```bash
tar -czf "$backup_file" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='your-custom-exclusion' \
    .
```

## 🆘 Troubleshooting

### Common Issues

#### Backup Creation Fails
```bash
# Check repository validation
./scripts/backup-manager.sh validate

# Check disk space
df -h

# Check permissions
ls -la scripts/backup-manager.sh
```

#### GitHub Actions Backup Fails
1. Check Actions tab for error details
2. Verify workflow file syntax
3. Check repository permissions
4. Review logs for specific errors

#### Restore Issues
```bash
# Verify backup file integrity
tar -tzf backup-file.tar.gz > /dev/null

# Check available space
df -h

# Validate backup contents
tar -tzf backup-file.tar.gz | head -20
```

## 📞 Support

For backup-related issues:

1. **Check Documentation**: Review this guide thoroughly
2. **Validate First**: Run `./scripts/backup-manager.sh validate`
3. **Check Actions**: Review GitHub Actions logs
4. **Test Locally**: Try manual backup creation
5. **GitHub Issues**: Report persistent issues

---

**Remember**: Backups are only useful if they can be restored successfully. Test your backup and restore procedures regularly to ensure they work when needed.