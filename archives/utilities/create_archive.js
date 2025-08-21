#!/usr/bin/env node

/**
 * Archive Creation Utility for WEB3 Project
 * 
 * This utility creates timestamped archives of repository state with detailed metadata.
 * Archives are immutable records of work performed on specific dates.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class ArchiveCreator {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '../..');
        this.archivesDir = path.join(this.projectRoot, 'archives');
        this.timestamp = this.generateTimestamp();
    }

    generateTimestamp() {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        
        return `${year}-${month}-${day}_${hours}-${minutes}-${seconds}`;
    }

    createArchive(description, workSummary, tags = [], useCases = '', notes = '') {
        if (!description || !workSummary) {
            throw new Error('Description and work summary are required');
        }

        const archiveName = `${this.timestamp}_${description.replace(/[^a-zA-Z0-9]/g, '_')}`;
        const archivePath = path.join(this.archivesDir, archiveName);

        console.log(`Creating archive: ${archiveName}`);

        // Create archive directory structure
        this.createDirectoryStructure(archivePath);

        // Create metadata files
        this.createMetadata(archivePath, description, workSummary, tags, useCases, notes);

        // Create snapshot of current repository state
        this.createSnapshot(archivePath);

        console.log(`Archive created successfully at: ${archivePath}`);
        return archivePath;
    }

    createDirectoryStructure(archivePath) {
        const dirs = [
            archivePath,
            path.join(archivePath, 'metadata'),
            path.join(archivePath, 'snapshot'),
            path.join(archivePath, 'sub_archives')
        ];

        dirs.forEach(dir => {
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
        });
    }

    createMetadata(archivePath, description, workSummary, tags, useCases, notes) {
        const metadataDir = path.join(archivePath, 'metadata');

        // Work summary
        const workSummaryContent = `# Work Summary - ${this.timestamp}

## Description
${description}

## Detailed Work Summary
${workSummary}

## Archive Created
${new Date().toISOString()}

## Repository State
- Commit: ${this.getGitCommit()}
- Branch: ${this.getGitBranch()}
- Status: ${this.getGitStatus()}
`;
        fs.writeFileSync(path.join(metadataDir, 'work_summary.md'), workSummaryContent);

        // Tags
        const tagsContent = tags.length > 0 ? tags.join('\n') : '# No tags specified';
        fs.writeFileSync(path.join(metadataDir, 'tags.txt'), tagsContent);

        // Use cases
        const useCasesContent = useCases || '# No use cases specified';
        fs.writeFileSync(path.join(metadataDir, 'use_cases.md'), useCasesContent);

        // Notes
        const notesContent = notes || '# No additional notes';
        fs.writeFileSync(path.join(metadataDir, 'notes.md'), notesContent);
    }

    createSnapshot(archivePath) {
        const snapshotDir = path.join(archivePath, 'snapshot');
        
        // Copy all repository files except .git, node_modules, and archives
        const excludePatterns = [
            '.git/',
            'node_modules/',
            'archives/',
            '*.log',
            '.DS_Store',
            'tmp/'
        ];

        // Create .gitignore for snapshot to exclude files we don't want to track
        const gitignoreContent = excludePatterns.join('\n');
        fs.writeFileSync(path.join(snapshotDir, '.gitignore'), gitignoreContent);

        // Use rsync to copy files efficiently while respecting exclusions
        try {
            const rsyncCmd = `rsync -av --exclude-from=${path.join(snapshotDir, '.gitignore')} ${this.projectRoot}/ ${snapshotDir}/`;
            execSync(rsyncCmd);
        } catch (error) {
            // Fallback to manual copy if rsync is not available
            this.copyDirectoryRecursive(this.projectRoot, snapshotDir, excludePatterns);
        }
    }

    copyDirectoryRecursive(source, target, excludePatterns) {
        if (!fs.existsSync(target)) {
            fs.mkdirSync(target, { recursive: true });
        }

        const files = fs.readdirSync(source);

        files.forEach(file => {
            const sourcePath = path.join(source, file);
            const targetPath = path.join(target, file);

            // Check if file should be excluded
            const shouldExclude = excludePatterns.some(pattern => {
                return file.includes(pattern.replace('/', '')) || sourcePath.includes(pattern);
            });

            if (shouldExclude) return;

            const stat = fs.statSync(sourcePath);

            if (stat.isDirectory()) {
                this.copyDirectoryRecursive(sourcePath, targetPath, excludePatterns);
            } else {
                fs.copyFileSync(sourcePath, targetPath);
            }
        });
    }

    getGitCommit() {
        try {
            return execSync('git rev-parse HEAD', { cwd: this.projectRoot }).toString().trim();
        } catch (error) {
            return 'Unable to determine commit';
        }
    }

    getGitBranch() {
        try {
            return execSync('git branch --show-current', { cwd: this.projectRoot }).toString().trim();
        } catch (error) {
            return 'Unable to determine branch';
        }
    }

    getGitStatus() {
        try {
            const status = execSync('git status --porcelain', { cwd: this.projectRoot }).toString().trim();
            return status || 'Clean working directory';
        } catch (error) {
            return 'Unable to determine status';
        }
    }
}

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.error('Usage: node create_archive.js <description> <work_summary> [tags] [use_cases] [notes]');
        console.error('Example: node create_archive.js "Initial Setup" "Created basic repository structure with Node.js server" "setup,nodejs,server"');
        process.exit(1);
    }

    const [description, workSummary, tagsStr = '', useCases = '', notes = ''] = args;
    const tags = tagsStr ? tagsStr.split(',').map(tag => tag.trim()) : [];

    try {
        const creator = new ArchiveCreator();
        creator.createArchive(description, workSummary, tags, useCases, notes);
    } catch (error) {
        console.error('Error creating archive:', error.message);
        process.exit(1);
    }
}

module.exports = ArchiveCreator;