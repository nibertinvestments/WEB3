# Archive System Usage Guide

## Overview

The WEB3 project archive system provides comprehensive tracking and documentation of all development work through timestamped, immutable records.

## When to Create Archives

Create archives when you have completed **actual development work**:

✅ **DO Archive:**
- Code changes (new features, bug fixes, refactoring)
- Configuration updates
- Documentation improvements
- Build/deployment setup changes
- Architecture decisions implementation
- Testing infrastructure changes

❌ **DON'T Archive:**
- Just reading/reviewing code
- Running existing tests without changes
- Checking repository status
- Exploratory work without concrete changes

## Creating Archives

### Using npm scripts (Recommended)

```bash
# Basic archive creation
npm run archive:create "Feature_Name" "Detailed description of work completed"

# With all metadata
npm run archive:create "Feature_Name" "Detailed work description" "tag1,tag2,tag3" "Use case description" "Additional notes"
```

### Using direct command

```bash
node archives/utilities/create_archive.js "<description>" "<work_summary>" "[tags]" "[use_cases]" "[notes]"
```

### Example

```bash
npm run archive:create "User_Authentication" "Implemented JWT-based user authentication system with login/logout endpoints and middleware protection" "auth,jwt,security,api" "Secure user login system for web application" "Uses bcrypt for password hashing and jsonwebtoken for session management"
```

## Managing Archives

### List all archives
```bash
npm run archive:list
```

### Validate archive integrity
```bash
npm run archive:validate
```

### Get detailed information
```bash
npm run archive:info <archive_name>
```

## Archive Structure

Each archive contains:

```
YYYY-MM-DD_HH-MM-SS_description/
├── metadata/
│   ├── work_summary.md    # Detailed work description
│   ├── tags.txt          # Categorization tags
│   ├── use_cases.md      # Intended use cases
│   └── notes.md          # Additional context
├── snapshot/             # Complete repository state
└── sub_archives/         # Future derivative work
```

## Working with Sub-Archives

When you use or reference previously archived work:

1. Navigate to the original archive's `sub_archives/` directory
2. Create a new timestamped subdirectory
3. Document how the archived work was used
4. Include links back to the original work

Example:
```
2025-01-15_10-30-22_User_Authentication/
└── sub_archives/
    └── 2025-01-20_14-15-30_Extended_For_OAuth/
        ├── usage_notes.md
        └── modifications/
```

## Best Practices

### Archive Naming
- Use descriptive names that clearly indicate the work done
- Use underscore separators for readability
- Keep descriptions concise but meaningful

### Work Summaries
- Include **what** was accomplished
- Include **why** the work was necessary
- Include **how** the implementation was approached
- Note any important decisions or trade-offs

### Tags
- Use consistent tagging across related work
- Include technology tags (nodejs, python, solidity)
- Include functional tags (auth, api, frontend, backend)
- Include type tags (feature, bugfix, refactor, docs)

### Use Cases
- Describe the intended applications
- Note any limitations or requirements
- Include examples of how to use the work

## Archive Validation

The system automatically validates:
- ✅ Proper directory structure
- ✅ Required metadata files exist and have content
- ✅ Snapshot directory contains repository state
- ✅ Timestamp format is correct

## Immutability Policy

**CRITICAL**: Once an archive is created, it must NEVER be modified:
- ❌ No editing existing archive content
- ❌ No deleting archive files
- ❌ No updating metadata retroactively
- ✅ Only add sub-archives for derivative work
- ✅ Create new archives for new work

This ensures complete traceability and proof of work progression.

## Integration with Development Workflow

1. **Complete development work**
2. **Test and validate changes**
3. **Create archive with detailed documentation**
4. **Validate archive was created correctly**
5. **Commit changes to version control**

The archive system complements (not replaces) Git version control by providing detailed documentation and organizational structure for development milestones.