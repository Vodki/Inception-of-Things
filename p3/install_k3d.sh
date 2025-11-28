#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (not recommended for most operations)
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_warning "Running as root. Some operations may not work correctly."
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker is running
docker_running() {
    if command_exists docker; then
        docker info >/dev/null 2>&1
    else
        return 1
    fi
}

# Run command with sudo if not root
run_with_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    elif command_exists sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

# Install Docker on Linux
install_docker_linux() {
    log_info "Installing Docker on Linux..."
    
    if command_exists docker; then
        log_success "Docker is already installed"
        if docker_running; then
            log_success "Docker is running"
            return 0
        else
            log_warning "Docker is installed but not running. Attempting to start..."
            if command_exists systemctl; then
                run_with_sudo systemctl start docker || log_warning "Could not start Docker service"
                run_with_sudo systemctl enable docker || log_warning "Could not enable Docker service"
            fi
            return 0
        fi
    fi
    
    # Detect package manager
    if command_exists apt-get; then
        log_info "Using apt-get to install Docker..."
        run_with_sudo apt-get update -y
        run_with_sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        run_with_sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_with_sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | run_with_sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        run_with_sudo apt-get update -y
        run_with_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Add user to docker group (if not root)
        if [ "$EUID" -ne 0 ]; then
            if command_exists sudo; then
                sudo usermod -aG docker "$USER"
                log_warning "You may need to log out and back in for Docker group changes to take effect"
            fi
        fi
        
        # Start Docker service
        if command_exists systemctl; then
            run_with_sudo systemctl start docker || true
            run_with_sudo systemctl enable docker || true
        fi
        
    elif command_exists yum; then
        log_info "Using yum to install Docker..."
        run_with_sudo yum install -y yum-utils
        run_with_sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        run_with_sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        if command_exists systemctl; then
            run_with_sudo systemctl start docker || true
            run_with_sudo systemctl enable docker || true
        fi
        
        if [ "$EUID" -ne 0 ]; then
            if command_exists sudo; then
                sudo usermod -aG docker "$USER"
                log_warning "You may need to log out and back in for Docker group changes to take effect"
            fi
        fi
        
    elif command_exists dnf; then
        log_info "Using dnf to install Docker..."
        run_with_sudo dnf install -y dnf-plugins-core
        run_with_sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        run_with_sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        if command_exists systemctl; then
            run_with_sudo systemctl start docker || true
            run_with_sudo systemctl enable docker || true
        fi
        
        if [ "$EUID" -ne 0 ]; then
            if command_exists sudo; then
                sudo usermod -aG docker "$USER"
                log_warning "You may need to log out and back in for Docker group changes to take effect"
            fi
        fi
        
    else
        log_error "Could not detect package manager (apt-get, yum, or dnf). Please install Docker manually."
        return 1
    fi
    
    # Verify Docker installation
    if docker_running; then
        log_success "Docker installed and running successfully"
    else
        log_warning "Docker installed but may not be running. Please start Docker manually."
    fi
}

# Check Docker on macOS
check_docker_macos() {
    log_info "Checking Docker on macOS..."
    
    if command_exists docker; then
        if docker_running; then
            log_success "Docker is installed and running"
            return 0
        else
            log_warning "Docker is installed but not running"
            log_info "Please start Docker Desktop manually from Applications"
            return 0
        fi
    fi
    
    # Check if Docker Desktop is installed but not in PATH
    if [ -d "/Applications/Docker.app" ]; then
        log_warning "Docker Desktop is installed but docker command is not in PATH"
        log_info "Please start Docker Desktop from Applications"
        return 0
    fi
    
    log_error "Docker is not installed on macOS"
    log_info "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    log_info "Or install via Homebrew: brew install --cask docker"
    return 1
}

# Install kubectl
install_kubectl() {
    log_info "Installing kubectl..."
    
    if command_exists kubectl; then
        local version
        version=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo "unknown")
        log_success "kubectl is already installed (version: $version)"
        return 0
    fi
    
    local os_type=$1
    local arch
    arch=$(uname -m)
    
    # Normalize architecture
    case "$arch" in
        x86_64)
            arch="amd64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    log_info "Detected architecture: $arch"
    
    # Get latest kubectl version
    local kubectl_version
    kubectl_version=$(curl -sL https://dl.k8s.io/release/stable.txt | tr -d 'v')
    
    if [ -z "$kubectl_version" ]; then
        log_error "Failed to fetch kubectl version"
        return 1
    fi
    
    log_info "Installing kubectl version: $kubectl_version"
    
    # Download kubectl
    local kubectl_url="https://dl.k8s.io/release/v${kubectl_version}/bin/${os_type}/${arch}/kubectl"
    local install_path="/usr/local/bin/kubectl"
    
    if [ "$EUID" -ne 0 ]; then
        install_path="${HOME}/.local/bin/kubectl"
        mkdir -p "$(dirname "$install_path")"
    fi
    
    log_info "Downloading kubectl from: $kubectl_url"
    curl -LO "$kubectl_url" || {
        log_error "Failed to download kubectl"
        return 1
    }
    
    # Verify checksum (optional but recommended)
    log_info "Verifying kubectl checksum..."
    curl -LO "https://dl.k8s.io/v${kubectl_version}/bin/${os_type}/${arch}/kubectl.sha256" || {
        log_warning "Could not verify checksum, continuing anyway..."
    }
    
    if [ -f "kubectl.sha256" ]; then
        if command_exists shasum; then
            if ! shasum -a 256 -c kubectl.sha256 < kubectl >/dev/null 2>&1; then
                log_warning "Checksum verification failed, but continuing..."
            else
                log_success "Checksum verified"
            fi
        fi
        rm -f kubectl.sha256
    fi
    
    # Make executable and install
    chmod +x kubectl
    mv kubectl "$install_path"
    if [ "$EUID" -ne 0 ]; then
        log_info "kubectl installed to $install_path"
        log_warning "Make sure $install_path is in your PATH"
    fi
    
    # Verify installation
    if command_exists kubectl; then
        log_success "kubectl installed successfully"
        kubectl version --client --short
    else
        log_warning "kubectl installed but not in PATH. Add $(dirname "$install_path") to your PATH"
    fi
}

# Install k3d
install_k3d() {
    log_info "Installing k3d..."
    
    if command_exists k3d; then
        local version
        version=$(k3d version 2>/dev/null | head -n1 || echo "unknown")
        log_success "k3d is already installed (version: $version)"
        return 0
    fi
    
    local os_type=$1
    
    # Try Homebrew first on macOS
    if [ "$os_type" = "darwin" ] && command_exists brew; then
        log_info "Installing k3d via Homebrew..."
        if brew install k3d; then
            log_success "k3d installed via Homebrew"
            return 0
        else
            log_warning "Homebrew installation failed, trying direct download..."
        fi
    fi
    
    # Direct installation using k3d install script
    log_info "Installing k3d using official install script..."
    if curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash; then
        log_success "k3d installed successfully"
        return 0
    else
        log_warning "Install script failed, trying manual installation..."
    fi
    
    # Manual installation
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            arch="amd64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    # Get latest k3d version
    local k3d_version
    k3d_version=$(curl -s https://api.github.com/repos/k3d-io/k3d/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | tr -d 'v')
    
    if [ -z "$k3d_version" ]; then
        log_error "Failed to fetch k3d version"
        return 1
    fi
    
    log_info "Installing k3d version: $k3d_version"
    
    local k3d_url="https://github.com/k3d-io/k3d/releases/download/v${k3d_version}/k3d-${os_type}-${arch}"
    local install_path="/usr/local/bin/k3d"
    
    if [ "$EUID" -ne 0 ]; then
        install_path="${HOME}/.local/bin/k3d"
        mkdir -p "$(dirname "$install_path")"
    fi
    
    log_info "Downloading k3d from: $k3d_url"
    curl -LO "$k3d_url" || {
        log_error "Failed to download k3d"
        return 1
    }
    
    chmod +x "k3d-${os_type}-${arch}"
    run_with_sudo mv "k3d-${os_type}-${arch}" "$install_path" 2>/dev/null || mv "k3d-${os_type}-${arch}" "$install_path"
    
    # Verify installation
    if command_exists k3d; then
        log_success "k3d installed successfully"
        k3d version
    else
        log_warning "k3d installed but not in PATH. Add $(dirname "$install_path") to your PATH"
    fi
}

# Main installation function
main() {
    # Check for mandatory argument
    if [ $# -eq 0 ]; then
        log_error "Usage: $0 <linux|macos>"
        log_info "Example: $0 linux"
        log_info "Example: $0 macos"
        exit 1
    fi
    
    local os_arg=$1
    
    # Normalize OS argument
    case "$os_arg" in
        linux|Linux|LINUX)
            os_type="linux"
            ;;
        macos|macOS|MACOS|darwin|Darwin|DARWIN)
            os_type="darwin"
            ;;
        *)
            log_error "Invalid OS argument: $os_arg"
            log_error "Must be 'linux' or 'macos'"
            exit 1
            ;;
    esac
    
    log_info "Starting k3d installation for: $os_type"
    log_info "=========================================="
    
    check_root
    
    # Install dependencies based on OS
    if [ "$os_type" = "linux" ]; then
        install_docker_linux
    else
        if ! check_docker_macos; then
            log_error "Docker is required for k3d. Please install Docker Desktop first."
            exit 1
        fi
    fi
    
    # Install kubectl
    install_kubectl "$os_type"
    
    # Install k3d
    install_k3d "$os_type"
    
    log_info "=========================================="
    log_success "Installation complete!"
    
    # Final verification
    log_info "Verifying installation..."
    if command_exists k3d; then
        log_success "k3d: $(k3d version | head -n1)"
    fi
    
    if command_exists kubectl; then
        log_success "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
    fi
    
    if docker_running; then
        log_success "Docker: $(docker --version)"
    else
        log_warning "Docker is not running. Please start Docker before using k3d."
    fi
    
    log_info ""
    log_info "You can now create a k3d cluster with:"
    log_info "  k3d cluster create <cluster-name>"
}

# Run main function
main "$@"

