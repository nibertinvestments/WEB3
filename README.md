# WEB3
This is the repository for all of Nibert Investments Web3 products

## Project Structure

This repository contains:
- **Node.js Server**: Basic HTTP server (`server.js`) serving on port 3000
- **Python Components**: Placeholder for Python development (`main.py`)
- **Solidity Components**: Placeholder for smart contract development (`main.sol`)
- **Archive System**: Comprehensive documentation and version control system

## Quick Start

```bash
# Install dependencies
npm install

# Start the server
npm start
# Server will be available at http://127.0.0.1:3000/

# Test the server
curl http://127.0.0.1:3000/
# Expected output: Hello World
```

## Archive System

This repository includes a comprehensive archive system for tracking all development work with timestamped, immutable records.

### Archive Commands

```bash
# List all archives
npm run archive:list

# Validate all archives
npm run archive:validate

# Get detailed info about an archive
npm run archive:info <archive_name>

# Create a new archive
npm run archive:create "<description>" "<work_summary>" "[tags]" "[use_cases]" "[notes]"
```

### Archive Structure

Archives are stored in the `archives/` directory with the following structure:
- Timestamped directories with complete work snapshots
- Detailed metadata including work summaries, tags, and use cases
- Immutable records that are never modified after creation
- Sub-archives for tracking derivative work

See `archives/README.md` for complete documentation.

## Development

- **Node.js**: Functional HTTP server component
- **Python**: Skeleton structure (development pending)
- **Solidity**: Skeleton structure (development pending)

All significant development work is automatically archived with timestamps and detailed documentation.
