#!/bin/bash

# ============================================================================
# Hoodi Validator Deployment Setup Script (FIXED)
# ============================================================================
# This script automates the setup of your validator deployment
# ============================================================================

set -e  # Exit on any error

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
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Hoodi Validator Deployment Setup Script            ║"
    echo "║                                                            ║"
    echo "║  This script will configure your validator deployment      ║"
    echo "║  with all necessary files and security settings.           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

print_section() {
    echo -e "${BLUE}=== $1 ===${NC}"
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
# Main Setup
# ============================================================================

print_header

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found!"
    print_info "Please run this script from the hoodi-validator-fixed directory"
    exit 1
fi

print_section "Checking Prerequisites"

# Check Docker
if command -v docker &> /dev/null; then
    print_success "Docker is installed"
else
    print_error "Docker is not installed"
    print_info "Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    print_success "Docker Compose is installed"
else
    print_error "Docker Compose is not installed"
    print_info "Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check OpenSSL
if command -v openssl &> /dev/null; then
    print_success "OpenSSL is installed"
else
    print_error "OpenSSL is not installed"
    exit 1
fi

# Check if running from correct directory
if [ ! -d "scripts" ] || [ ! -d "docs" ]; then
    print_error "Required directories not found"
    print_info "Make sure you're in the hoodi-validator-fixed root directory"
    exit 1
fi

print_success "Running from correct directory"

# ============================================================================
# Create Data Directories FIRST (BEFORE JWT GENERATION)
# ============================================================================

print_section "Creating Data Directories"

mkdir -p data/execution
print_success "Created data/execution"

mkdir -p data/beacon
print_success "Created data/beacon"

mkdir -p data/validator
print_success "Created data/validator"

# CREATE JWT DIRECTORY BEFORE TRYING TO WRITE TO IT
mkdir -p jwt
print_success "Created jwt directory"

mkdir -p secrets
print_success "Created secrets directory"

mkdir -p backups
print_success "Created backups directory"

# ============================================================================
# Generate JWT Secret (NOW THAT DIRECTORY EXISTS)
# ============================================================================

print_section "Generating JWT Secret"

if [ -f "jwt/jwtsecret" ]; then
    print_warning "JWT secret already exists"
    read -p "Do you want to regenerate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        openssl rand -hex 32 > jwt/jwtsecret
        chmod 600 jwt/jwtsecret
        print_success "Generated new JWT secret"
    else
        print_info "Keeping existing JWT secret"
    fi
else
    openssl rand -hex 32 > jwt/jwtsecret
    chmod 600 jwt/jwtsecret
    print_success "Generated JWT secret"
fi

# ============================================================================
# Create .env Configuration File
# ============================================================================

print_section "Creating .env Configuration File"

if [ -f ".env" ]; then
    print_warning ".env file already exists"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Keeping existing .env file"
    else
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
        else
            print_error ".env.example not found!"
            exit 1
        fi
    fi
else
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success "Created .env from .env.example"
    else
        print_error ".env.example not found!"
        print_info "Make sure .env.example exists in the deployment directory"
        exit 1
    fi
fi

# ============================================================================
# Create Validator Password File
# ============================================================================

print_section "Setting Up Validator Password"

if [ -f "secrets/wallet-password.txt" ]; then
    print_warning "Validator password file already exists"
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -sp "Enter validator password (min 12 chars): " VALIDATOR_PASSWORD
        echo
        read -sp "Confirm password: " VALIDATOR_PASSWORD_CONFIRM
        echo
        
        if [ "$VALIDATOR_PASSWORD" != "$VALIDATOR_PASSWORD_CONFIRM" ]; then
            print_error "Passwords do not match!"
            exit 1
        fi
        
        if [ ${#VALIDATOR_PASSWORD} -lt 12 ]; then
            print_error "Password must be at least 12 characters long"
            exit 1
        fi
        
        echo "$VALIDATOR_PASSWORD" > secrets/wallet-password.txt
        chmod 600 secrets/wallet-password.txt
        print_success "Updated validator password"
    else
        print_info "Keeping existing password"
    fi
else
    read -sp "Enter validator password (min 12 chars): " VALIDATOR_PASSWORD
    echo
    read -sp "Confirm password: " VALIDATOR_PASSWORD_CONFIRM
    echo
    
    if [ "$VALIDATOR_PASSWORD" != "$VALIDATOR_PASSWORD_CONFIRM" ]; then
        print_error "Passwords do not match!"
        exit 1
    fi
    
    if [ ${#VALIDATOR_PASSWORD} -lt 12 ]; then
        print_error "Password must be at least 12 characters long"
        exit 1
    fi
    
    echo "$VALIDATOR_PASSWORD" > secrets/wallet-password.txt
    chmod 600 secrets/wallet-password.txt
    print_success "Created validator password file"
fi

# ============================================================================
# Create .gitignore
# ============================================================================

print_section "Setting Up Git Configuration"

if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Environment variables
.env
.env.local
.env.*.local

# Secrets
secrets/
jwt/jwtsecret

# Validator keys
data/validator/
validator_keys/

# Docker volumes
data/execution/
data/beacon/

# Backups
backups/
*.tar.gz
*.zip

# System files
.DS_Store
*.swp
*.swo
*~
.vscode/
.idea/

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
EOF
    print_success "Created .gitignore"
else
    print_info ".gitignore already exists"
fi

# ============================================================================
# Verify Configuration
# ============================================================================

print_section "Verifying Configuration"

# Check .env file
if [ -f ".env" ]; then
    print_success ".env file exists"
    
    # Check for critical variables
    if grep -q "FEE_RECIPIENT=0x0000000000000000000000000000000000000000" .env; then
        print_warning "FEE_RECIPIENT is still set to null address (0x0000...)"
        print_info "Update .env with your Ethereum address before deploying"
    fi
    
    if grep -q "VALIDATOR_PASSWORD=your-secure-password-here" .env; then
        print_warning "VALIDATOR_PASSWORD is still set to default"
        print_info "Update .env with your password before deploying"
    fi
else
    print_error ".env file not found!"
    exit 1
fi

# Check directories
for dir in data/execution data/beacon data/validator jwt secrets backups; do
    if [ -d "$dir" ]; then
        print_success "$dir directory exists"
    else
        print_error "$dir directory not found"
        exit 1
    fi
done

# Check JWT secret
if [ -f "jwt/jwtsecret" ]; then
    print_success "JWT secret exists"
    JWT_SECRET=$(cat jwt/jwtsecret)
    if [ ${#JWT_SECRET} -eq 64 ]; then
        print_success "JWT secret is valid (64 hex characters)"
    else
        print_warning "JWT secret length is ${#JWT_SECRET} characters (expected 64)"
    fi
else
    print_error "JWT secret not found"
    exit 1
fi

# ============================================================================
# Summary and Next Steps
# ============================================================================

print_section "Setup Complete!"

echo ""
echo "✓ All prerequisites checked"
echo "✓ Configuration files created"
echo "✓ Data directories initialized"
echo "✓ JWT secret generated"
echo ""

print_warning "IMPORTANT: Before deploying, complete these steps:"
echo ""
echo "1. Edit .env and set your configuration:"
echo "   nano .env"
echo ""
echo "2. Set your FEE_RECIPIENT address (Ethereum address for rewards)"
echo ""
echo "3. Ensure VALIDATOR_PASSWORD is set to a strong password"
echo ""
echo "4. Generate validator keys on your LOCAL machine:"
echo "   git clone https://github.com/ethereum/staking-deposit-cli.git"
echo "   python3 deposit.py new-mnemonic --chain hoodi"
echo ""
echo "5. Copy validator keys to this server:"
echo "   scp -r ~/validator_keys user@server:~/hoodi-validator-fixed/data/validator/"
echo ""
echo "6. Deploy the stack:"
echo "   docker compose up -d"
echo ""
echo "7. Monitor the deployment:"
echo "   docker compose logs -f"
echo ""

print_info "For more information, see docs/QUICK_START.md"
echo ""
