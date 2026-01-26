# Hoodi Validator - Complete Deployment Package

**All-in-one Hoodi validator setup with Geth, Prysm Beacon, MEV-Boost, and Validator Client**

![Status](https://img.shields.io/badge/status-production%20ready-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-2.0-blue)

---

## 🚀 Quick Start (5 minutes)

```bash
# 1. Run setup script
./scripts/setup.sh

# 2. Generate validator keys (on local machine)
git clone https://github.com/ethereum/staking-deposit-cli.git
cd staking-deposit-cli
python3 deposit.py new-mnemonic --chain hoodi

# 3. Copy keys to server
scp -r ~/validator_keys user@server:~/hoodi-validator/data/validator/

# 4. Start services
docker compose up -d

# 5. Monitor
docker compose logs -f

# 6. Deposit ETH (after beacon syncs)
# Go to: https://cheap.hoodi.launchpad.ethstaker.cc
```

---

## ✨ Features

### 🔧 All-in-One Setup
- **Execution Layer**: Geth v1.15.1 with optimized caching and pruning
- **Consensus Layer**: Prysm Beacon v5.3.0 with checkpoint sync
- **Validator Client**: Prysm Validator v5.3.0 with doppelgänger protection
- **MEV Optimization**: MEV-Boost v1.7 with multiple relay support

### 🛡️ Security Features
- ✅ Environment variable configuration (.env file)
- ✅ Automatic JWT secret generation
- ✅ Doppelgänger protection enabled
- ✅ RPC endpoints bound to localhost
- ✅ Metrics ports secured
- ✅ Resource limits configured
- ✅ Logging with rotation

### 📊 Performance Optimized
- ✅ Geth cache configuration (4096 MB)
- ✅ State pruning enabled
- ✅ Multiple MEV relays for redundancy
- ✅ Checkpoint sync for fast beacon sync
- ✅ Docker resource limits
- ✅ Healthchecks for all services

### 📖 Complete Documentation
- ✅ Quick start guide (5 minutes)
- ✅ Full deployment guide (step-by-step)
- ✅ Troubleshooting guide (30+ issues)
- ✅ Performance tuning guide
- ✅ Monitoring setup guide

### 🔄 Easy Management
- ✅ Automated setup script
- ✅ Environment variable configuration
- ✅ Docker Compose orchestration
- ✅ Health checks and monitoring
- ✅ Backup and restore procedures

---

## 📋 Requirements

### System Requirements
- **CPU**: 4+ cores (8+ recommended)
- **RAM**: 32 GB minimum (64 GB recommended)
- **Storage**: 1 TB+ SSD
- **Network**: 100+ Mbps (1+ Gbps recommended)

### Software Requirements
- Docker 20.10+
- Docker Compose 2.0+
- OpenSSL (for JWT generation)
- Git (optional)

### Hoodi Network
- **Network**: Hoodi Testnet
- **Chain ID**: 560048
- **Faucet**: https://hoodi.ethpandaops.io
- **Launchpad**: https://cheap.hoodi.launchpad.ethstaker.cc

---

## 🔧 Installation

### Step 1: Clone Repository
```bash
git clone https://github.com/YOUR-USERNAME/hoodi-validator.git
cd hoodi-validator
```

### Step 2: Run Setup Script
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script will:
- ✅ Check Docker and Docker Compose
- ✅ Create `.env` configuration file
- ✅ Generate JWT secret
- ✅ Create data directories
- ✅ Pull Docker images
- ✅ Verify everything is ready

### Step 3: Configure (if needed)
```bash
# Edit configuration
nano .env

# Key settings:
# FEE_RECIPIENT=0xYourEthereumAddress
# VALIDATOR_PASSWORD=YourSecurePassword
# GETH_CACHE=4096
```

---

## 🚀 Deployment

### Generate Validator Keys (Local Machine)
```bash
# On your LOCAL machine (NOT the server!)
git clone https://github.com/ethereum/staking-deposit-cli.git
cd staking-deposit-cli
pip install -r requirements.txt
python3 deposit.py new-mnemonic --chain hoodi

# SAVE YOUR MNEMONIC OFFLINE (pen & paper only!)
```

### Copy Keys to Server
```bash
# On your local machine
scp -r ~/validator_keys user@server:~/hoodi-validator/data/validator/
scp ~/deposit_data-*.json user@server:~/hoodi-validator/
```

### Start Services
```bash
# On the server
docker compose up -d

# Monitor startup
docker compose logs -f
```

### Wait for Sync
```bash
# Check Beacon sync
curl http://localhost:5052/eth/v1/node/syncing

# Wait until: "is_syncing": false
```

### Deposit ETH
```bash
# Go to: https://cheap.hoodi.launchpad.ethstaker.cc
# Upload deposit_data-*.json
# Send 32+ Hoodi ETH per validator
```

### Wait for Activation
```bash
# Monitor validator
docker compose logs -f validator

# Wait 6-12 hours for activation
# Validator starts automatically!
```

---

## 📊 Services & Ports

| Service | Ports | Purpose |
|---------|-------|---------|
| **Geth** | 8545, 8546, 30303 | Execution Layer |
| **Beacon** | 4000, 5052, 13000, 12000 | Consensus Layer |
| **MEV-Boost** | 3500 | MEV Optimization |
| **Validator** | 8009 | Validator Client |

All RPC and metrics ports are bound to localhost (127.0.0.1) for security.

---

## 🎯 Common Commands

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

# View resource usage
docker stats

# Check disk usage
du -sh data/*/
```

---

## 🔍 Monitoring

### Check Service Health
```bash
# All services
docker compose ps

# Specific service logs
docker compose logs -f geth
docker compose logs -f beacon
docker compose logs -f validator
docker compose logs -f mev-boost
```

### Check Sync Status
```bash
# Geth sync
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Beacon sync
curl http://localhost:5052/eth/v1/node/syncing

# Validator status
docker compose logs validator | grep -i "validating\|attesting"
```

### Monitor Resources
```bash
# Real-time stats
docker stats

# Disk usage
df -h
du -sh data/geth
du -sh data/beacon

# Memory usage
free -h
```

---

## 📚 Documentation

- **[Quick Start](docs/QUICK_START.md)** - 5-minute setup guide
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Complete step-by-step guide
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - 30+ common issues and solutions
- **[Performance Tuning](docs/PERFORMANCE.md)** - Optimization guide
- **[Monitoring](docs/MONITORING.md)** - Monitoring setup

---

## 🔐 Security

### Critical Security Steps
- ✅ Generate validator keys on **LOCAL machine** (NOT on server!)
- ✅ Write mnemonic **OFFLINE** (pen & paper, never digital)
- ✅ Use **strong password** (12+ characters, mixed types)
- ✅ Update `FEE_RECIPIENT` with YOUR Ethereum address
- ✅ Never use exchange address for fee recipient
- ✅ Never share your mnemonic with anyone
- ✅ Never run same keys in two places (SLASHING!)
- ✅ Backup validator keys regularly
- ✅ Keep `.env` file private (protected by .gitignore)

### Security Features
- RPC endpoints bound to localhost only
- Metrics ports secured
- JWT secret auto-generated
- Resource limits configured
- Logging with rotation
- Doppelgänger protection enabled

---

## 🔄 Backup & Recovery

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

---

## 🆘 Troubleshooting

### Services Won't Start
```bash
# Check logs
docker compose logs

# Validate configuration
docker compose config

# Check prerequisites
ls -la jwt/jwtsecret
ls -la secrets/wallet-password.txt
ls -la .env
```

### Beacon Won't Sync
```bash
# Check Geth is healthy
docker compose logs geth

# Restart Beacon
docker compose restart beacon

# Monitor sync
docker compose logs -f beacon
```

### Validator Not Attesting
```bash
# Check Beacon is synced
curl http://localhost:5052/eth/v1/node/syncing

# Check validator logs
docker compose logs -f validator

# Verify keys exist
ls -la data/validator/validator_keys/
```

See [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for 30+ common issues and solutions.

---

## 📈 Performance Tips

1. **Adjust Geth Cache**: Edit `GETH_CACHE` in `.env` based on available RAM
2. **Limit Peers**: Reduce `GETH_MAX_PEERS` and `BEACON_MAX_PEERS` if CPU is high
3. **Monitor Resources**: Use `docker stats` to track usage
4. **Optimize Storage**: Geth prunes automatically, but monitor disk usage
5. **Update Clients**: Check for new versions monthly

See [Performance Tuning Guide](docs/PERFORMANCE.md) for detailed optimization.

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## ⚠️ Disclaimer

This software is provided as-is for educational and testing purposes on the Hoodi testnet. Always test thoroughly before running on mainnet. Never use with real funds unless you fully understand the risks.

---

## 🔗 Resources

- **Discord**: https://discord.gg/ethstaker
- **Documentation**: https://docs.ethstaker.org
- **Hoodi Faucet**: https://hoodi.ethpandaops.io
- **Hoodi Launchpad**: https://cheap.hoodi.launchpad.ethstaker.cc
- **Hoodi Explorer**: https://hoodi.etherscan.io
- **Beacon Explorer**: https://hoodi.beaconcha.in

---

## 📞 Support

- **Issues**: Open an issue on GitHub
- **Discussions**: Start a discussion in the repository
- **Community**: Join https://discord.gg/ethstaker

---

## 🎉 Ready to Validate!

```bash
# Quick setup
./scripts/setup.sh
docker compose up -d

# Generate keys and deposit ETH
# Start validating on Hoodi! 🚀
```

**Happy validating!** 💰

---

**Last Updated**: January 2024  
**Version**: 2.0  
**Status**: Production Ready ✅
