#!/bin/bash
# PSM Enterprise - Linux Server Setup
# Layer 1: Linux Foundation
# Supports: Ubuntu, Debian, RHEL, Fedora, Oracle Linux

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     PSM ENTERPRISE - LINUX SERVER SETUP                    ║"
echo "║     Layer 1: Linux Foundation                              ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif [ -f /etc/redhat-release ]; then
    OS="Red Hat"
else
    OS=$(uname -s)
fi

echo "Detected OS: $OS $VER"

# Package manager detection
if command -v apt-get &> /dev/null; then
    PKG_MGR="apt-get"
    PKG_UPDATE="apt-get update"
    PKG_INSTALL="apt-get install -y"
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    PKG_UPDATE="dnf check-update || true"
    PKG_INSTALL="dnf install -y"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    PKG_UPDATE="yum check-update || true"
    PKG_INSTALL="yum install -y"
fi

echo "Package Manager: $PKG_MGR"

# Essential packages
ESSENTIALS="curl wget git vim htop tmux jq unzip"

install_essentials() {
    echo "[+] Installing essential packages..."
    $PKG_UPDATE
    $PKG_INSTALL $ESSENTIALS
}

# Docker installation
install_docker() {
    echo "[+] Installing Docker..."
    if command -v docker &> /dev/null; then
        echo "    Docker already installed"
        return
    fi

    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    usermod -aG docker $USER
}

# Node.js installation
install_nodejs() {
    echo "[+] Installing Node.js..."
    if command -v node &> /dev/null; then
        echo "    Node.js already installed: $(node -v)"
        return
    fi

    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    $PKG_INSTALL nodejs
}

# Firewall setup
configure_firewall() {
    echo "[+] Configuring firewall..."
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp    # SSH
        ufw allow 80/tcp    # HTTP
        ufw allow 443/tcp   # HTTPS
        ufw allow 8096/tcp  # Jellyfin
        ufw allow 3001/tcp  # PSM Processor
        ufw allow 3002/tcp  # API Gateway
        ufw --force enable
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=22/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=8096/tcp
        firewall-cmd --permanent --add-port=3001/tcp
        firewall-cmd --permanent --add-port=3002/tcp
        firewall-cmd --reload
    fi
}

# Create PSM user
create_psm_user() {
    echo "[+] Creating PSM service user..."
    if id "psm" &>/dev/null; then
        echo "    User 'psm' already exists"
    else
        useradd -m -s /bin/bash psm
        usermod -aG docker psm
    fi
}

# Setup directories
setup_directories() {
    echo "[+] Setting up directories..."
    mkdir -p /opt/psm/{config,data,logs,scripts}
    mkdir -p /var/log/psm
    chown -R psm:psm /opt/psm /var/log/psm
}

# Main
main() {
    install_essentials
    install_docker
    install_nodejs
    configure_firewall
    create_psm_user
    setup_directories

    echo ""
    echo "✅ Linux foundation setup complete!"
    echo ""
    echo "Next steps:"
    echo "  - Run container setup: ./containers/docker-compose.yml"
    echo "  - Configure monitoring: ./observability/prometheus.yml"
}

# Run if called with --execute flag
if [ "$1" == "--execute" ]; then
    main
else
    echo ""
    echo "Dry run - add --execute flag to run setup"
    echo "Commands that would be executed:"
    echo "  - Install: $ESSENTIALS"
    echo "  - Install Docker"
    echo "  - Install Node.js 20.x"
    echo "  - Configure firewall"
    echo "  - Create PSM user"
fi
