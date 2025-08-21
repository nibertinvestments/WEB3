#!/usr/bin/env node

/**
 * Archive Validation Utility for WEB3 Project
 * 
 * This utility validates the integrity and structure of archives.
 * Ensures archives maintain their immutable state and proper organization.
 */

const fs = require('fs');
const path = require('path');

class ArchiveValidator {
    constructor() {
        this.projectRoot = path.resolve(__dirname, '../..');
        this.archivesDir = path.join(this.projectRoot, 'archives');
    }

    validateAllArchives() {
        console.log('Validating all archives...');
        
        if (!fs.existsSync(this.archivesDir)) {
            console.error('Archives directory does not exist');
            return false;
        }

        const archives = this.getArchiveDirectories();
        let allValid = true;

        for (const archive of archives) {
            const archivePath = path.join(this.archivesDir, archive);
            console.log(`\nValidating archive: ${archive}`);
            
            if (!this.validateArchive(archivePath)) {
                allValid = false;
            }
        }

        if (allValid) {
            console.log('\n✅ All archives are valid');
        } else {
            console.log('\n❌ Some archives have validation errors');
        }

        return allValid;
    }

    validateArchive(archivePath) {
        const archiveName = path.basename(archivePath);
        let isValid = true;

        // Check directory structure
        if (!this.validateDirectoryStructure(archivePath)) {
            console.error(`❌ Invalid directory structure in ${archiveName}`);
            isValid = false;
        }

        // Check metadata files
        if (!this.validateMetadata(archivePath)) {
            console.error(`❌ Invalid metadata in ${archiveName}`);
            isValid = false;
        }

        // Check snapshot
        if (!this.validateSnapshot(archivePath)) {
            console.error(`❌ Invalid snapshot in ${archiveName}`);
            isValid = false;
        }

        // Check timestamp format
        if (!this.validateTimestamp(archiveName)) {
            console.error(`❌ Invalid timestamp format in ${archiveName}`);
            isValid = false;
        }

        if (isValid) {
            console.log(`✅ Archive ${archiveName} is valid`);
        }

        return isValid;
    }

    validateDirectoryStructure(archivePath) {
        const requiredDirs = [
            'metadata',
            'snapshot',
            'sub_archives'
        ];

        for (const dir of requiredDirs) {
            const dirPath = path.join(archivePath, dir);
            if (!fs.existsSync(dirPath) || !fs.statSync(dirPath).isDirectory()) {
                console.error(`Missing required directory: ${dir}`);
                return false;
            }
        }

        return true;
    }

    validateMetadata(archivePath) {
        const metadataDir = path.join(archivePath, 'metadata');
        const requiredFiles = [
            'work_summary.md',
            'tags.txt',
            'use_cases.md',
            'notes.md'
        ];

        for (const file of requiredFiles) {
            const filePath = path.join(metadataDir, file);
            if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
                console.error(`Missing required metadata file: ${file}`);
                return false;
            }

            // Check if file has content (not just empty)
            const content = fs.readFileSync(filePath, 'utf8').trim();
            if (!content) {
                console.error(`Empty metadata file: ${file}`);
                return false;
            }
        }

        return true;
    }

    validateSnapshot(archivePath) {
        const snapshotDir = path.join(archivePath, 'snapshot');
        
        if (!fs.existsSync(snapshotDir) || !fs.statSync(snapshotDir).isDirectory()) {
            console.error('Missing snapshot directory');
            return false;
        }

        // Check if snapshot has content
        const files = fs.readdirSync(snapshotDir);
        if (files.length === 0) {
            console.error('Empty snapshot directory');
            return false;
        }

        return true;
    }

    validateTimestamp(archiveName) {
        // Expected format: YYYY-MM-DD_HH-MM-SS_description
        const timestampRegex = /^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_/;
        return timestampRegex.test(archiveName);
    }

    getArchiveDirectories() {
        if (!fs.existsSync(this.archivesDir)) {
            return [];
        }

        return fs.readdirSync(this.archivesDir)
            .filter(item => {
                const itemPath = path.join(this.archivesDir, item);
                return fs.statSync(itemPath).isDirectory() && 
                       item !== 'utilities' && 
                       !item.startsWith('.');
            })
            .sort();
    }

    getArchiveInfo(archiveName) {
        const archivePath = path.join(this.archivesDir, archiveName);
        
        if (!fs.existsSync(archivePath)) {
            return null;
        }

        const workSummaryPath = path.join(archivePath, 'metadata', 'work_summary.md');
        const tagsPath = path.join(archivePath, 'metadata', 'tags.txt');

        let workSummary = '';
        let tags = [];

        try {
            if (fs.existsSync(workSummaryPath)) {
                workSummary = fs.readFileSync(workSummaryPath, 'utf8');
            }
            
            if (fs.existsSync(tagsPath)) {
                const tagsContent = fs.readFileSync(tagsPath, 'utf8').trim();
                tags = tagsContent.split('\n').filter(tag => tag.trim() && !tag.startsWith('#'));
            }
        } catch (error) {
            console.warn(`Error reading archive info for ${archiveName}:`, error.message);
        }

        return {
            name: archiveName,
            path: archivePath,
            workSummary,
            tags
        };
    }

    listArchives() {
        console.log('📁 WEB3 Project Archives\n');
        
        const archives = this.getArchiveDirectories();
        
        if (archives.length === 0) {
            console.log('No archives found.');
            return;
        }

        archives.forEach(archive => {
            const info = this.getArchiveInfo(archive);
            console.log(`📋 ${archive}`);
            
            if (info) {
                if (info.tags.length > 0) {
                    console.log(`   Tags: ${info.tags.join(', ')}`);
                }
                
                // Extract description from work summary
                const lines = info.workSummary.split('\n');
                const descriptionLine = lines.find(line => line.startsWith('## Description'));
                if (descriptionLine) {
                    const descIndex = lines.indexOf(descriptionLine);
                    if (descIndex + 1 < lines.length) {
                        const description = lines[descIndex + 1].trim();
                        console.log(`   Description: ${description}`);
                    }
                }
            }
            
            console.log('');
        });
    }
}

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    const command = args[0] || 'validate';

    const validator = new ArchiveValidator();

    switch (command) {
        case 'validate':
            const isValid = validator.validateAllArchives();
            process.exit(isValid ? 0 : 1);
            break;
            
        case 'list':
            validator.listArchives();
            break;
            
        case 'info':
            if (args[1]) {
                const info = validator.getArchiveInfo(args[1]);
                if (info) {
                    console.log('Archive Information:');
                    console.log(`Name: ${info.name}`);
                    console.log(`Path: ${info.path}`);
                    console.log(`Tags: ${info.tags.join(', ')}`);
                    console.log('\nWork Summary:');
                    console.log(info.workSummary);
                } else {
                    console.error(`Archive not found: ${args[1]}`);
                    process.exit(1);
                }
            } else {
                console.error('Usage: node validate_archive.js info <archive_name>');
                process.exit(1);
            }
            break;
            
        default:
            console.error('Usage: node validate_archive.js [validate|list|info] [archive_name]');
            console.error('Commands:');
            console.error('  validate - Validate all archives (default)');
            console.error('  list     - List all archives with basic info');
            console.error('  info     - Show detailed info for specific archive');
            process.exit(1);
    }
}

module.exports = ArchiveValidator;