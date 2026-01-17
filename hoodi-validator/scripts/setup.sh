#!/bin/bash

# ============================================================================
# Hoodi Validator Setup Script
# ============================================================================
# This script automates the setup of the Hoodi validator deployment
# Usage: ./scripts/setup.sh
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Check Prerequisites
# ============================================================================

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        echo "Install Docker from: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed"

    # Check if Docker Compose is installed
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose v2.0+ is not installed"
        echo "Install Docker Compose from: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose is installed"

    # Check if openssl is installed
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed"
        exit 1
    fi
    print_success "OpenSSL is installed"

    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please run this script from the deployment directory."
        exit 1
    fi
    print_success "Running from correct directory"
}

# ============================================================================
# Create .env File
# ============================================================================

create_env_file() {
    print_header "Creating .env Configuration File"

    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to reconfigure it? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping .env configuration"
            return
        fi
    fi

    # Copy template
    cp .env.example .env
    print_success "Created .env from template"

    # Interactive configuration
    print_info "Please answer the following questions to configure your validator:"
    echo

    # Fee Recipient
    read -p "Enter your Ethereum address for fee recipient: " fee_recipient
    if [[ ! $fee_recipient =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        print_error "Invalid Ethereum address format"
        exit 1
    fi
    sed -i "s/FEE_RECIPIENT=.*/FEE_RECIPIENT=$fee_recipient/" .env
    print_success "Fee recipient set to $fee_recipient"

    # Validator Password
    read -sp "Enter your validator wallet password (12+ chars, mixed types): " validator_password
    echo
    if [ ${#validator_password} -lt 12 ]; then
        print_error "Password must be at least 12 characters"
        exit 1
    fi
    echo "$validator_password" > secrets/wallet-password.txt
    chmod 600 secrets/wallet-password.txt
    print_success "Validator password set"

    # Validator Graffiti
    read -p "Enter validator graffiti (optional, max 32 chars): " validator_graffiti
    if [ ! -z "$validator_graffiti" ]; then
        if [ ${#validator_graffiti} -gt 32 ]; then
            print_error "Graffiti must be max 32 characters"
            exit 1
        fi
        sed -i "s/VALIDATOR_GRAFFITI=.*/VALIDATOR_GRAFFITI=$validator_graffiti/" .env
        print_success "Validator graffiti set to $validator_graffiti"
    fi

    # Geth Cache
    read -p "Enter Geth cache size in MB (default 4096): " geth_cache
    geth_cache=${geth_cache:-4096}
    sed -i "s/GETH_CACHE=.*/GETH_CACHE=$geth_cache/" .env
    print_success "Geth cache set to $geth_cache MB"

    # Public IP (optional)
    read -p "Enter your public IP address (optional, for NAT traversal): " public_ip
    if [ ! -z "$public_ip" ]; then
        sed -i "s/GETH_NAT_IP=.*/GETH_NAT_IP=$public_ip/" .env
        print_success "Public IP set to $public_ip"
    fi

    echo
    print_success ".env file configured successfully"
}

# ============================================================================
# Generate JWT Secret
# ============================================================================

generate_jwt_secret() {
    print_header "Generating JWT Secret"

    if [ -f "jwt/jwtsecret" ]; then
        print_warning "JWT secret already exists"
        read -p "Do you want to generate a new one? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing JWT secret"
            return
        fi
    fi

    openssl rand -hex 32 > jwt/jwtsecret
    chmod 600 jwt/jwtsecret
    print_success "JWT secret generated"
}

# ============================================================================
# Create Data Directories
# ============================================================================

create_data_directories() {
    print_header "Creating Data Directories"

    mkdir -p data/geth
    mkdir -p data/beacon
    mkdir -p data/validator
    mkdir -p secrets

    chmod 700 data
    chmod 700 data/geth
    chmod 700 data/beacon
    chmod 700 data/validator
    chmod 700 secrets

    print_success "Data directories created with proper permissions"
}

# ============================================================================
# Verify Configuration
# ============================================================================

verify_configuration() {
    print_header "Verifying Configuration"

    # Check .env file
    if [ ! -f ".env" ]; then
        print_error ".env file not found"
        exit 1
    fi
    print_success ".env file exists"

    # Check JWT secret
    if [ ! -f "jwt/jwtsecret" ]; then
        print_error "JWT secret not found"
        exit 1
    fi
    print_success "JWT secret exists"

    # Check wallet password
    if [ ! -f "secrets/wallet-password.txt" ]; then
        print_error "Wallet password file not found"
        exit 1
    fi
    print_success "Wallet password file exists"

    # Check fee recipient is not null address
    fee_recipient=$(grep "^FEE_RECIPIENT=" .env | cut -d'=' -f2)
    if [ "$fee_recipient" = "0x0000000000000000000000000000000000000000" ]; then
        print_error "Fee recipient is still the null address! Please update .env"
        exit 1
    fi
    print_success "Fee recipient is set: $fee_recipient"

    # Check password is not placeholder
    password=$(cat secrets/wallet-password.txt)
    if [ "$password" = "your-secure-password-here" ]; then
        print_error "Wallet password is still the placeholder! Please update it"
        exit 1
    fi
    print_success "Wallet password is configured"

    # Check docker-compose.yml
    if ! docker compose config > /dev/null 2>&1; then
        print_error "docker-compose.yml has errors"
        docker compose config
        exit 1
    fi
    print_success "docker-compose.yml is valid"
}

# ============================================================================
# Pull Docker Images
# ============================================================================

pull_docker_images() {
    print_header "Pulling Docker Images"

    print_info "This may take a few minutes..."
    docker compose pull

    print_success "Docker images pulled successfully"
}

# ============================================================================
# Display Summary
# ============================================================================

display_summary() {
    print_header "Setup Complete!"

    echo "Your Hoodi validator is configured and ready to deploy."
    echo
    echo "Configuration Summary:"
    echo "  Fee Recipient: $(grep '^FEE_RECIPIENT=' .env | cut -d'=' -f2)"
    echo "  Geth Cache: $(grep '^GETH_CACHE=' .env | cut -d'=' -f2) MB"
    echo "  Validator Graffiti: $(grep '^VALIDATOR_GRAFFITI=' .env | cut -d'=' -f2)"
    echo
    echo "Next Steps:"
    echo "  1. Review .env file: nano .env"
    echo "  2. Copy validator keys to: data/validator/validator_keys/"
    echo "  3. Start services: docker compose up -d"
    echo "  4. Monitor logs: docker compose logs -f"
    echo "  5. Wait for sync: curl http://localhost:5052/eth/v1/node/syncing"
    echo "  6. Deposit ETH: https://cheap.hoodi.launchpad.ethstaker.cc"
    echo
    echo "Documentation:"
    echo "  - Quick Start: cat docs/QUICK_START.md"
    echo "  - Full Guide: cat docs/DEPLOYMENT_GUIDE.md"
    echo "  - Troubleshooting: cat docs/TROUBLESHOOTING.md"
    echo
    print_success "Setup script completed successfully!"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Hoodi Validator Deployment Setup Script            ║"
    echo "║                                                            ║"
    echo "║  This script will configure your validator deployment      ║"
    echo "║  with all necessary files and security settings.           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_prerequisites
    create_env_file
    generate_jwt_secret
    create_data_directories
    verify_configuration
    pull_docker_images
    display_summary
}

# Run main function
main "$@"
