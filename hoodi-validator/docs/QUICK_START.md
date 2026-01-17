# Hoodi Validator - Quick Start Guide

## 5-Minute Setup

### Step 1: Run Setup Script
```bash
./scripts/setup.sh
```

This script will:
- ✅ Check Docker and Docker Compose
- ✅ Create .env configuration file
- ✅ Generate JWT secret
- ✅ Create data directories
- ✅ Pull Docker images
- ✅ Verify everything is ready

### Step 2: Generate Validator Keys (Local Machine)
```bash
# On your LOCAL machine (NOT the server!)
git clone https://github.com/ethereum/staking-deposit-cli.git
cd staking-deposit-cli
pip install -r requirements.txt
python3 deposit.py new-mnemonic --chain hoodi

# SAVE YOUR MNEMONIC OFFLINE (pen & paper only!)
# You'll get: validator_keys/ folder and deposit_data-*.json
```

### Step 3: Copy Keys to Server
```bash
# On your LOCAL machine
scp -r ~/validator_keys user@server:~/hoodi-validator-fixed/data/validator/
scp ~/deposit_data-*.json user@server:~/hoodi-validator-fixed/
```

### Step 4: Start Services
```bash
# On the server
docker compose up -d

# Monitor startup
docker compose logs -f
```

### Step 5: Wait for Sync
```bash
# Check Beacon sync
curl http://localhost:5052/eth/v1/node/syncing

# Wait until: "is_syncing": false
```

### Step 6: Deposit ETH
```bash
# Go to: https://cheap.hoodi.launchpad.ethstaker.cc
# Upload deposit_data-*.json
# Send 32+ Hoodi ETH per validator
# Get free Hoodi ETH: https://hoodi.ethpandaops.io
```

### Step 7: Wait for Activation
```bash
# Monitor validator
docker compose logs -f validator

# Wait 6-12 hours for activation
# Validator starts automatically!
```

---

## Common Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f
docker compose logs -f beacon
docker compose logs -f validator

# Check status
docker compose ps

# Check Beacon sync
curl http://localhost:5052/eth/v1/node/syncing

# Check MEV-Boost
curl http://localhost:3500/

# Restart a service
docker compose restart beacon
```

---

## Configuration

All configuration is in `.env` file. Edit with:
```bash
nano .env
```

Key settings:
- `FEE_RECIPIENT` - Your Ethereum address (for rewards)
- `VALIDATOR_PASSWORD` - Your wallet password
- `GETH_CACHE` - Geth memory cache
- `MEV_RELAYS` - MEV relay URLs

---

## Troubleshooting

### Services won't start
```bash
docker compose logs
docker compose config  # Check for errors
```

### Beacon won't sync
```bash
docker compose restart beacon
docker compose logs -f beacon
```

### Validator not attesting
```bash
curl http://localhost:5052/eth/v1/node/syncing
docker compose logs validator
```

### Running out of disk space
```bash
df -h
du -sh data/*/
```

---

## Next Steps

- Read full guide: `docs/DEPLOYMENT_GUIDE.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Performance tuning: `docs/PERFORMANCE.md`
- Monitoring: `docs/MONITORING.md`

---

**Ready to validate! 🚀**
