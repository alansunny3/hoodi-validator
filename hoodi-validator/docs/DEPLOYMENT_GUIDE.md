# Hoodi Validator - Complete Deployment Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Deployment](#deployment)
6. [Verification](#verification)
7. [Monitoring](#monitoring)
8. [Maintenance](#maintenance)

---

## Prerequisites

### Required Software
- Docker 20.10+
- Docker Compose 2.0+
- OpenSSL (for JWT secret generation)
- Git (optional, for version control)

### Installation

**Ubuntu/Debian:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**macOS:**
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Docker Compose is included
```

**Windows:**
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Docker Compose is included
```

---

## System Requirements

### Minimum (Testnet)
- **CPU**: 4 cores
- **RAM**: 32 GB
- **Storage**: 500 GB SSD
- **Network**: 100+ Mbps

### Recommended (Production)
- **CPU**: 8+ cores
- **RAM**: 64 GB
- **Storage**: 1 TB+ SSD
- **Network**: 1+ Gbps

### Storage Growth
- Geth: ~14 GB/week (with pruning)
- Beacon: ~3 GB/week
- Validator: ~100 MB/week

---

## Installation

### Step 1: Clone or Download Repository

```bash
# Using Git
git clone https://github.com/YOUR-USERNAME/hoodi-validator.git
cd hoodi-validator

# Or download and extract
cd hoodi-validator
```

### Step 2: Run Setup Script

```bash
# Make script executable
chmod +x scripts/setup.sh

# Run setup
./scripts/setup.sh
```

The setup script will:
1. Check Docker and Docker Compose
2. Create `.env` configuration file
3. Generate JWT secret
4. Create data directories
5. Pull Docker images
6. Verify configuration

---

## Configuration

### Environment Variables (.env)

All configuration is managed through the `.env` file. Key variables:

#### Critical Settings
```env
# Your Ethereum address (where rewards go)
FEE_RECIPIENT=0x1234567890123456789012345678901234567890

# Your validator wallet password
VALIDATOR_PASSWORD=YourSecurePassword123!@#
```

#### Geth Settings
```env
# Cache size in MB (adjust for your RAM)
GETH_CACHE=4096

# Maximum peers
GETH_MAX_PEERS=50

# Your public IP (for NAT traversal)
GETH_NAT_IP=0.0.0.0
```

#### Beacon Settings
```env
# Maximum peers
BEACON_MAX_PEERS=80

# Checkpoint sync URL
BEACON_CHECKPOINT_SYNC_URL=https://hoodi.beaconstate.ethstaker.cc
```

#### MEV-Boost Settings
```env
# Relay URLs (comma-separated)
MEV_RELAYS=https://0xaa58...@hoodi.titanrelay.xyz,https://0x821f...@bloxroute.hoodi.blxrbdn.com
```

#### Resource Limits
```env
# Geth resources
GETH_CPU_LIMIT=4
GETH_MEMORY_LIMIT=8G

# Beacon resources
BEACON_CPU_LIMIT=4
BEACON_MEMORY_LIMIT=16G

# Validator resources
VALIDATOR_CPU_LIMIT=2
VALIDATOR_MEMORY_LIMIT=4G
```

### Edit Configuration

```bash
# Edit .env file
nano .env

# Key settings to update:
# 1. FEE_RECIPIENT - Your Ethereum address
# 2. VALIDATOR_PASSWORD - Your password
# 3. GETH_CACHE - Adjust for your RAM
# 4. GETH_NAT_IP - Your public IP (optional)
```

---

## Deployment

### Step 1: Generate Validator Keys

**Important: Do this on your LOCAL machine, NOT the server!**

```bash
# Clone staking-deposit-cli
git clone https://github.com/ethereum/staking-deposit-cli.git
cd staking-deposit-cli

# Install dependencies
pip install -r requirements.txt

# Generate keys
python3 deposit.py new-mnemonic --chain hoodi

# SAVE YOUR MNEMONIC OFFLINE (pen & paper only!)
# You'll get:
# - validator_keys/ folder
# - deposit_data-*.json file
```

### Step 2: Copy Keys to Server

```bash
# On your local machine
scp -r ~/validator_keys user@server:~/hoodi-validator/data/validator/
scp ~/deposit_data-*.json user@server:~/hoodi-validator/
```

### Step 3: Start Services

```bash
# On the server
cd ~/hoodi-validator

# Start all services
docker compose up -d

# Check status
docker compose ps

# Monitor startup
docker compose logs -f
```

### Step 4: Wait for Sync

```bash
# Check Geth sync
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Check Beacon sync
curl http://localhost:5052/eth/v1/node/syncing

# Wait until both return: false or "is_syncing": false
# This typically takes 5-15 minutes
```

### Step 5: Deposit ETH

Once beacon is synced:

1. Go to: https://cheap.hoodi.launchpad.ethstaker.cc
2. Upload `deposit_data-*.json`
3. Send 32+ Hoodi ETH per validator
4. Get free Hoodi ETH: https://hoodi.ethpandaops.io

### Step 6: Wait for Activation

```bash
# Monitor validator activation
docker compose logs -f validator

# Check validator status
curl http://localhost:5052/eth/v1/beacon/states/head/validators

# Wait 6-12 hours for activation
# Validator will start automatically
```

---

## Verification

### Check Geth (Execution Layer)

```bash
# Sync status
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Expected: "false" when synced

# Peer count
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'

# Expected: Non-zero peer count

# Check logs
docker compose logs geth | tail -20
```

### Check Beacon (Consensus Layer)

```bash
# Sync status
curl http://localhost:5052/eth/v1/node/syncing

# Expected: "is_syncing": false

# Peer count
curl http://localhost:5052/eth/v1/node/peers

# Expected: Multiple peers

# Check logs
docker compose logs beacon | tail -20
```

### Check Validator (Validator Client)

```bash
# Validator status
docker compose logs validator | grep -i "validating\|attesting"

# Check metrics
curl http://localhost:8009/metrics | grep validator

# Check logs
docker compose logs validator | tail -20
```

### Check MEV-Boost

```bash
# Health check
curl http://localhost:3500/

# Expected: HTTP 200 response

# Check relay connections
docker compose logs mev-boost | grep -i "relay\|connected"

# Check logs
docker compose logs mev-boost | tail -20
```

---

## Monitoring

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f geth
docker compose logs -f beacon
docker compose logs -f validator
docker compose logs -f mev-boost

# Last N lines
docker compose logs -f --tail=100 beacon

# Search for errors
docker compose logs | grep -i error
```

### Check Resources

```bash
# Docker stats (real-time)
docker stats

# Disk usage
df -h
du -sh data/geth
du -sh data/beacon
du -sh data/validator

# Memory usage
free -h

# Network connections
netstat -an | grep -E "30303|13000|12000"
```

### Health Checks

```bash
# Service status
docker compose ps

# Container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Restart count
docker inspect hoodi-geth | grep RestartCount
```

---

## Maintenance

### Daily Tasks
- [ ] Check validator is attesting
- [ ] Check MEV-Boost is connected
- [ ] Monitor disk usage
- [ ] Check for errors in logs

### Weekly Tasks
- [ ] Check for client updates
- [ ] Review error logs
- [ ] Verify fee recipient is receiving rewards
- [ ] Check peer count

### Monthly Tasks
- [ ] Backup validator keys
- [ ] Update client versions if available
- [ ] Review performance metrics
- [ ] Test disaster recovery

### Backup Validator Keys

```bash
# Create backup
tar -czf validator_backup_$(date +%Y%m%d).tar.gz data/validator/

# Store securely (offline or encrypted cloud storage)
```

### Restore from Backup

```bash
# Stop services
docker compose down

# Restore backup
tar -xzf validator_backup_YYYYMMDD.tar.gz

# Start services
docker compose up -d

# Verify
docker compose logs -f validator
```

### Update Client Versions

```bash
# Edit .env file
nano .env

# Update version variables:
# GETH_VERSION=v1.15.2
# BEACON_VERSION=v5.3.1
# VALIDATOR_VERSION=v5.3.1
# MEV_BOOST_VERSION=v1.8

# Pull new images
docker compose pull

# Restart services
docker compose down
docker compose up -d

# Verify
docker compose logs -f
```

---

## Troubleshooting

See `docs/TROUBLESHOOTING.md` for common issues and solutions.

---

## Support

- **Discord**: https://discord.gg/ethstaker
- **Documentation**: https://docs.ethstaker.org
- **Issues**: Open an issue on GitHub

---

**Ready to validate on Hoodi! 🚀**
