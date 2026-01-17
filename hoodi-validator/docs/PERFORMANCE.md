# Hoodi Validator - Performance Tuning Guide

## Optimization Overview

This guide provides recommendations for optimizing your Hoodi validator deployment for maximum performance and efficiency.

---

## Geth (Execution Layer) Optimization

### Cache Configuration

The Geth cache is the most important performance setting. Adjust based on available RAM:

```env
# For 32 GB RAM: 4096 MB (recommended minimum)
GETH_CACHE=4096

# For 64 GB RAM: 8192 MB (recommended)
GETH_CACHE=8192

# For 128 GB RAM: 16384 MB (maximum recommended)
GETH_CACHE=16384
```

**Impact**: Larger cache = faster state operations, lower latency

### Peer Configuration

```env
# Testnet (Hoodi): 50 peers
GETH_MAX_PEERS=50

# Mainnet: 100-200 peers
# Adjust if CPU usage is high
```

**Impact**: More peers = better network propagation, higher CPU usage

### Sync Mode

```env
# snap = faster initial sync, higher bandwidth
GETH_SYNC_MODE=snap

# full = slower initial sync, lower bandwidth
# Use full if bandwidth is limited
GETH_SYNC_MODE=full
```

**Impact**: Snap is 2-3x faster for initial sync

### State Scheme

```env
# path = efficient pruning (recommended)
GETH_STATE_SCHEME=path

# hash = legacy, not recommended
GETH_STATE_SCHEME=hash
```

**Impact**: Path scheme uses 50% less disk space

### Garbage Collection

```env
# full = continuous pruning (recommended)
GETH_GC_MODE=full

# archive = keep all state (not recommended)
# Requires 10x more disk space
GETH_GC_MODE=full
```

---

## Beacon (Consensus Layer) Optimization

### Peer Configuration

```env
# Testnet (Hoodi): 80 peers
BEACON_MAX_PEERS=80

# Mainnet: 100-150 peers
# Increase if you have good network
BEACON_MAX_PEERS=100
```

**Impact**: More peers = better block propagation

### Checkpoint Sync

```env
# Use checkpoint sync for fast initial sync
BEACON_CHECKPOINT_SYNC_URL=https://hoodi.beaconstate.ethstaker.cc
```

**Impact**: 100x faster initial sync (5 min vs 5 hours)

---

## MEV-Boost Optimization

### Multiple Relays

```env
# Use multiple relays for redundancy and better rewards
MEV_RELAYS=https://relay1@url1,https://relay2@url2,https://relay3@url3

# Hoodi relays:
# - Titan Relay
# - Bloxroute
# - Flashbots
# - Aestus
# - Ultra Sound
```

**Impact**: Multiple relays = higher MEV rewards, better reliability

### Relay Failover

MEV-Boost automatically failovers between relays if one is down.

---

## Resource Allocation

### CPU Allocation

```env
# Geth: 4 cores (minimum 2)
GETH_CPU_LIMIT=4
GETH_CPU_RESERVATION=2

# Beacon: 4 cores (minimum 2)
BEACON_CPU_LIMIT=4
BEACON_CPU_RESERVATION=2

# Validator: 2 cores (minimum 1)
VALIDATOR_CPU_LIMIT=2
VALIDATOR_CPU_RESERVATION=1

# MEV-Boost: 1 core
MEV_CPU_LIMIT=1
MEV_CPU_RESERVATION=0.5
```

**Adjustment**: Reduce if CPU usage is high, increase if available

### Memory Allocation

```env
# Geth: 8 GB (minimum 4 GB)
GETH_MEMORY_LIMIT=8G
GETH_MEMORY_RESERVATION=4G

# Beacon: 16 GB (minimum 8 GB)
BEACON_MEMORY_LIMIT=16G
BEACON_MEMORY_RESERVATION=8G

# Validator: 4 GB (minimum 2 GB)
VALIDATOR_MEMORY_LIMIT=4G
VALIDATOR_MEMORY_RESERVATION=2G

# MEV-Boost: 2 GB (minimum 1 GB)
MEV_MEMORY_LIMIT=2G
MEV_MEMORY_RESERVATION=1G
```

**Adjustment**: Reduce if memory usage is high, increase if available

---

## Network Optimization

### Firewall Configuration

```bash
# Open P2P ports
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
sudo ufw allow 13000/tcp
sudo ufw allow 12000/udp

# Limit RPC access to localhost
sudo ufw allow from 127.0.0.1 to any port 8545
sudo ufw allow from 127.0.0.1 to any port 5052
```

### NAT Traversal

```env
# Set your public IP for better P2P connectivity
GETH_NAT_IP=YOUR.PUBLIC.IP.ADDRESS

# Or use automatic detection
GETH_NAT_IP=0.0.0.0
```

### Bandwidth Optimization

```bash
# Monitor bandwidth usage
iftop -i eth0

# Limit bandwidth if needed
# (Use tc command for traffic control)
```

---

## Disk Optimization

### Storage Monitoring

```bash
# Check disk usage
df -h

# Monitor growth over time
watch -n 60 'du -sh data/geth'

# Check individual service sizes
du -sh data/geth
du -sh data/beacon
du -sh data/validator
```

### Pruning

Geth automatically prunes with `--gcmode=full` and `--state.scheme=path`.

**Expected growth:**
- Geth: ~14 GB/week (with pruning)
- Beacon: ~3 GB/week
- Validator: ~100 MB/week

### Storage Expansion

If running low on space:

```bash
# Option 1: Add new disk
# Mount at /data/geth or /data/beacon

# Option 2: Resync with better pruning
docker compose down
rm -rf data/geth
docker compose up -d
```

---

## Logging Optimization

### Log Rotation

```env
# Limit log file size
LOGGING_MAX_SIZE=100m

# Keep only 3 log files
LOGGING_MAX_FILE=3
```

### Log Levels

```env
# Set appropriate log level
LOG_LEVEL=info

# Options: trace, debug, info, warn, error
# trace = most verbose, error = least verbose
```

### Log Monitoring

```bash
# Monitor logs in real-time
docker compose logs -f

# Search for errors
docker compose logs | grep -i error

# Export logs
docker compose logs > logs.txt
```

---

## Monitoring & Metrics

### Docker Stats

```bash
# Real-time resource usage
docker stats

# Specific service
docker stats hoodi-geth

# Update every 5 seconds
docker stats --no-stream
```

### Prometheus Metrics

```bash
# Geth metrics
curl http://localhost:6060/metrics

# Beacon metrics
curl http://localhost:8008/metrics

# Validator metrics
curl http://localhost:8009/metrics
```

### Health Checks

```bash
# Check all services
docker compose ps

# Check specific service health
docker inspect hoodi-geth | grep -A 5 "Health"

# Manual health check
curl http://localhost:5052/eth/v1/node/health
```

---

## Performance Tuning Checklist

### Initial Setup
- [ ] Adjust `GETH_CACHE` based on available RAM
- [ ] Set `GETH_NAT_IP` to your public IP
- [ ] Configure multiple MEV relays
- [ ] Set appropriate resource limits

### Ongoing Optimization
- [ ] Monitor `docker stats` daily
- [ ] Check disk usage weekly
- [ ] Review logs for errors
- [ ] Adjust peer counts if needed

### Advanced Optimization
- [ ] Tune CPU/memory allocation
- [ ] Optimize network settings
- [ ] Configure firewall rules
- [ ] Set up monitoring/alerting

---

## Performance Benchmarks

### Expected Performance

**Geth (Execution Layer):**
- Sync time: 5-15 minutes (with snap sync)
- Peer count: 20-50 peers
- CPU usage: 10-30% (during sync, 5-10% idle)
- Memory usage: 4-8 GB
- Disk growth: ~14 GB/week

**Beacon (Consensus Layer):**
- Sync time: 2-5 minutes (with checkpoint sync)
- Peer count: 30-80 peers
- CPU usage: 5-15%
- Memory usage: 8-16 GB
- Disk growth: ~3 GB/week

**Validator (Validator Client):**
- CPU usage: 1-5%
- Memory usage: 2-4 GB
- Attestation success: >99%

**MEV-Boost:**
- CPU usage: <1%
- Memory usage: 1-2 GB
- Relay connections: 3-5 relays

### Optimization Impact

| Change | CPU | Memory | Disk | Network |
|--------|-----|--------|------|---------|
| Increase cache | ↓ 10% | ↑ 2GB | - | - |
| Reduce peers | ↓ 20% | ↓ 5% | - | ↓ 10% |
| Enable pruning | - | - | ↓ 50% | - |
| Multiple relays | ↑ 5% | ↑ 10% | - | ↑ 20% |

---

## Troubleshooting Performance

### High CPU Usage

```bash
# Check which service
docker stats

# Reduce cache size
GETH_CACHE=2048

# Reduce peer count
GETH_MAX_PEERS=30

# Restart services
docker compose down
docker compose up -d
```

### High Memory Usage

```bash
# Check which service
docker stats

# Reduce memory limits
GETH_MEMORY_LIMIT=4G
BEACON_MEMORY_LIMIT=8G

# Restart services
docker compose down
docker compose up -d
```

### Slow Sync

```bash
# Check peer count
curl http://localhost:5052/eth/v1/node/peers

# Increase peer count
BEACON_MAX_PEERS=120

# Check network connectivity
ping 8.8.8.8

# Restart services
docker compose restart
```

### Disk Space Issues

```bash
# Check usage
df -h
du -sh data/*/

# Enable pruning
GETH_GC_MODE=full
GETH_STATE_SCHEME=path

# Restart Geth
docker compose restart geth
```

---

## Advanced Tuning

### Custom Geth Flags

Edit `docker-compose.yml` to add custom flags:

```yaml
command:
  - --hoodi
  - --datadir=/data/geth
  # Add custom flags here
  - --custom-flag=value
```

### Custom Beacon Flags

Edit `docker-compose.yml` to add custom flags:

```yaml
command:
  - --hoodi
  - --datadir=/data/beacon
  # Add custom flags here
  - --custom-flag=value
```

### Custom Validator Flags

Edit `docker-compose.yml` to add custom flags:

```yaml
command:
  - --hoodi
  # Add custom flags here
  - --custom-flag=value
```

---

## Performance Monitoring Tools

### System Monitoring
- `docker stats` - Docker resource usage
- `htop` - System resource usage
- `iotop` - Disk I/O usage
- `nethogs` - Network usage

### Blockchain Monitoring
- `curl` - Manual API queries
- Prometheus - Metrics collection
- Grafana - Metrics visualization
- Beaconcha.in - Validator monitoring

---

## Optimization Summary

1. **Start with defaults** - They're well-tuned for most systems
2. **Monitor performance** - Use `docker stats` and logs
3. **Adjust gradually** - Change one setting at a time
4. **Test thoroughly** - Verify changes improve performance
5. **Document changes** - Keep track of what works

---

## Resources

- [Geth Documentation](https://geth.ethereum.org/docs)
- [Prysm Documentation](https://docs.prylabs.network)
- [MEV-Boost Documentation](https://github.com/flashbots/mev-boost)
- [Ethereum Staking Guide](https://docs.ethstaker.org)

---

**Happy optimizing! 🚀**
