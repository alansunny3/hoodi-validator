# Hoodi Validator - Troubleshooting Guide

## Common Issues and Solutions

### Services Won't Start

**Problem:** `docker compose up -d` fails or services crash immediately

**Solution:**

```bash
# Check error logs
docker compose logs

# Validate configuration
docker compose config

# Check for missing files
ls -la jwt/jwtsecret
ls -la secrets/wallet-password.txt
ls -la .env

# Restart services
docker compose restart

# Check Docker daemon
docker ps
```

**Common Causes:**
- Missing `.env` file → Run `./scripts/setup.sh`
- Missing JWT secret → Run `openssl rand -hex 32 > jwt/jwtsecret`
- Missing password file → Create `secrets/wallet-password.txt`
- Port already in use → Check with `netstat -an | grep 8545`

---

### Geth Won't Sync

**Problem:** Geth stuck at low sync percentage

**Symptoms:**
```bash
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Returns: "syncing": true with low block numbers
```

**Solution:**

```bash
# Check Geth logs
docker compose logs -f geth

# Check peer count
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'

# If no peers, restart Geth
docker compose restart geth

# Wait for peers to connect (5-10 minutes)
docker compose logs -f geth | grep "peers"

# Check disk space
df -h
du -sh data/geth
```

**Common Causes:**
- Not enough peers → Wait for peer discovery
- Low disk space → Free up space or increase storage
- Network connectivity → Check firewall rules
- Corrupted data → Delete data/geth and resync

---

### Beacon Won't Sync

**Problem:** Beacon stuck syncing or won't start

**Symptoms:**
```bash
curl http://localhost:5052/eth/v1/node/syncing

# Returns: "is_syncing": true or error
```

**Solution:**

```bash
# Check Beacon logs
docker compose logs -f beacon

# Check if Geth is healthy
docker compose logs geth | grep -i "synced\|error"

# Restart Beacon
docker compose restart beacon

# Wait for checkpoint sync (2-5 minutes)
docker compose logs -f beacon | grep -i "checkpoint\|synced"

# Check Beacon health
curl http://localhost:5052/eth/v1/node/health
```

**Common Causes:**
- Geth not synced → Wait for Geth to sync first
- Checkpoint sync URL down → Check URL is accessible
- Insufficient peers → Wait for peer discovery
- Corrupted data → Delete data/beacon and resync

---

### Validator Not Attesting

**Problem:** Validator not proposing or attesting blocks

**Symptoms:**
```bash
docker compose logs validator | grep -i "error\|warning"

# No "attesting" or "proposing" messages
```

**Solution:**

```bash
# Check Beacon is synced
curl http://localhost:5052/eth/v1/node/syncing

# Expected: "is_syncing": false

# Check validator logs
docker compose logs -f validator

# Check validator password is correct
cat secrets/wallet-password.txt

# Verify validator keys exist
ls -la data/validator/validator_keys/

# Check validator metrics
curl http://localhost:8009/metrics | grep validator

# Restart validator
docker compose restart validator

# Wait for activation (6-12 hours after deposit)
docker compose logs -f validator | grep -i "validating\|attesting"
```

**Common Causes:**
- Beacon not synced → Wait for Beacon sync
- Validator keys not imported → Check keys in data/validator/validator_keys/
- Wrong password → Update secrets/wallet-password.txt
- Validator not activated → Wait 6-12 hours after deposit
- Insufficient balance → Deposit 32+ Hoodi ETH

---

### MEV-Boost Not Connecting

**Problem:** MEV-Boost can't connect to relays

**Symptoms:**
```bash
curl http://localhost:3500/

# Error or timeout

docker compose logs mev-boost | grep -i "error\|relay"

# No relay connections
```

**Solution:**

```bash
# Check MEV-Boost health
curl http://localhost:3500/

# Check MEV-Boost logs
docker compose logs -f mev-boost

# Test relay connectivity
curl https://hoodi.titanrelay.xyz/
curl https://bloxroute.hoodi.blxrbdn.com/

# Check relay URLs in .env
grep MEV_RELAYS .env

# Restart MEV-Boost
docker compose restart mev-boost

# Check Beacon sees MEV-Boost
docker compose logs beacon | grep -i "mev"
```

**Common Causes:**
- Relay URLs down → Check relay status
- Network connectivity → Check firewall
- Invalid relay URLs → Update MEV_RELAYS in .env
- MEV-Boost not healthy → Restart service

---

### Running Out of Disk Space

**Problem:** Disk space filling up quickly

**Symptoms:**
```bash
df -h

# Filesystem is 90%+ full

du -sh data/*/

# data/geth is very large
```

**Solution:**

```bash
# Check current usage
df -h
du -sh data/geth
du -sh data/beacon
du -sh data/validator

# Geth should prune automatically
# If not, force pruning:
docker compose exec geth geth --hoodi --datadir=/data/geth prune-state

# Or delete and resync (if space is critical):
docker compose down
rm -rf data/geth
docker compose up -d

# Monitor growth
watch -n 60 'du -sh data/geth'
```

**Common Causes:**
- Pruning not working → Check Geth configuration
- Too many logs → Rotate logs with `docker compose logs --tail=0`
- Validator keys backup → Clean up old backups

---

### High CPU Usage

**Problem:** Services using excessive CPU

**Symptoms:**
```bash
docker stats

# CPU usage > 80%
```

**Solution:**

```bash
# Check which service is using CPU
docker stats

# Check service logs
docker compose logs SERVICE_NAME

# Reduce cache size
nano .env
# Reduce GETH_CACHE=2048 (from 4096)

# Restart services
docker compose down
docker compose up -d

# Monitor
docker stats
```

**Common Causes:**
- Syncing in progress → Normal during startup
- Cache too large → Reduce GETH_CACHE
- Too many peers → Reduce GETH_MAX_PEERS
- Corrupted data → Resync

---

### High Memory Usage

**Problem:** Services using excessive memory

**Symptoms:**
```bash
docker stats

# Memory usage > 90%

free -h

# Available memory < 1 GB
```

**Solution:**

```bash
# Check memory usage
docker stats
free -h

# Reduce resource limits in .env
nano .env
# Reduce GETH_MEMORY_LIMIT=4G
# Reduce BEACON_MEMORY_LIMIT=8G

# Restart services
docker compose down
docker compose up -d

# Monitor
docker stats
```

**Common Causes:**
- Memory leak → Restart service
- Cache too large → Reduce GETH_CACHE
- Too many peers → Reduce peer limits
- Insufficient system RAM → Upgrade machine

---

### Validator Keys Import Failed

**Problem:** Validator can't import keys

**Symptoms:**
```bash
docker compose logs validator | grep -i "error\|import"

# "wallet not found" or "password incorrect"
```

**Solution:**

```bash
# Check keys exist
ls -la data/validator/validator_keys/

# Check password is correct
cat secrets/wallet-password.txt

# Verify password matches key generation password

# Check key permissions
chmod 700 data/validator/validator_keys/

# Restart validator
docker compose restart validator

# Check logs
docker compose logs -f validator
```

**Common Causes:**
- Keys not copied → Copy keys from local machine
- Wrong password → Update secrets/wallet-password.txt
- Corrupted keys → Regenerate keys
- Permission issues → Fix directory permissions

---

### Network Connectivity Issues

**Problem:** Services can't connect to network

**Symptoms:**
```bash
docker compose logs | grep -i "network\|connection\|peer"

# Low peer count
# Can't connect to relays
```

**Solution:**

```bash
# Check network connectivity
ping 8.8.8.8

# Check firewall rules
sudo ufw status

# Open required ports
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
sudo ufw allow 13000/tcp
sudo ufw allow 12000/udp

# Check port forwarding
netstat -an | grep -E "30303|13000|12000"

# Restart networking
docker compose restart

# Check peer count
curl http://localhost:5052/eth/v1/node/peers
```

**Common Causes:**
- Firewall blocking ports → Open ports
- NAT issues → Configure GETH_NAT_IP
- ISP blocking ports → Use VPN or change ISP
- Network congestion → Wait or reduce peer count

---

### Docker Compose Errors

**Problem:** `docker compose` command fails

**Symptoms:**
```bash
docker compose up -d

# Error: "docker: command not found"
# Or: "docker-compose: command not found"
```

**Solution:**

```bash
# Check Docker installation
docker --version

# Check Docker Compose installation
docker compose version

# If not installed, install Docker Compose v2.0+
# See: https://docs.docker.com/compose/install/

# Verify installation
docker compose version

# Try again
docker compose up -d
```

**Common Causes:**
- Docker not installed → Install Docker
- Docker Compose v1 installed → Upgrade to v2.0+
- Docker daemon not running → Start Docker

---

### Permission Denied Errors

**Problem:** Permission errors when running commands

**Symptoms:**
```bash
docker compose up -d

# Error: "permission denied"
```

**Solution:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify
docker ps

# If still issues, use sudo
sudo docker compose up -d
```

---

### Corrupted Data

**Problem:** Services crash due to corrupted data

**Symptoms:**
```bash
docker compose logs | grep -i "corrupt\|invalid\|error"

# Services restart repeatedly
```

**Solution:**

```bash
# Stop services
docker compose down

# Backup corrupted data
tar -czf data_backup_corrupted.tar.gz data/

# Delete corrupted data
rm -rf data/geth
rm -rf data/beacon
# Keep data/validator (validator keys)

# Restart services
docker compose up -d

# Resync will begin automatically
docker compose logs -f geth
docker compose logs -f beacon
```

---

## Getting Help

If you can't solve the issue:

1. **Check logs:**
   ```bash
   docker compose logs > logs.txt
   ```

2. **Gather system info:**
   ```bash
   docker stats > stats.txt
   df -h >> stats.txt
   free -h >> stats.txt
   ```

3. **Ask for help:**
   - Discord: https://discord.gg/ethstaker
   - GitHub Issues: Open an issue with logs
   - Include: logs, system info, .env (without secrets)

---

## Prevention

- **Regular backups:** `tar -czf validator_backup_$(date +%Y%m%d).tar.gz data/validator/`
- **Monitor resources:** `docker stats`
- **Check logs daily:** `docker compose logs | grep -i error`
- **Update clients:** Check for new versions monthly
- **Test recovery:** Practice restoring from backups

---

**Need more help? Join the community at https://discord.gg/ethstaker**
