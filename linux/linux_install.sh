#!/bin/bash

# Aide Installation Script for All Linux Distros
# Ensure the script is run with sudo privileges

# Variables
_pkgname="aide"
arch=$(uname -m)
install_dir="/opt/aide"

# Fetch the latest release version from GitHub
fetch_latest_version() {
    echo "Fetching latest Aide release version..."
    latest_release_info=$(curl -s https://api.github.com/repos/codestoryai/binaries/releases/latest)
    pkgver=$(echo "$latest_release_info" | grep -Po '"tag_name": "\K[0-9.]+')
    if [[ -z "$pkgver" ]]; then
        echo "Error: Unable to fetch the latest version."
        exit 1
    fi
    echo "Latest version: $pkgver"
}

# Define the correct tarball URL based on architecture
set_tarball_url() {
    url="https://github.com/codestoryai/binaries/releases/download/${pkgver}"
    if [[ "$arch" == "x86_64" ]]; then
        tarball="${_pkgname}-linux-x64-${pkgver}.tar.gz"
    elif [[ "$arch" == "aarch64" ]]; then
        tarball="${_pkgname}-linux-arm64-${pkgver}.tar.gz"
    else
        echo "Unsupported architecture: $arch"
        exit 1
    fi
    download_url="${url}/${tarball}"
}

# Check for required dependencies and install if missing
install_dependencies() {
    echo "Checking for required dependencies..."

    # List of common dependencies
    dependencies=(
        "fontconfig"
        "libxtst"
        "gtk3"
        "python"
        "cairo"
        "alsa-lib"
        "nss"
        "gcc-libs"
        "libnotify"
        "libxss"
        "glibc"
        "bash"
    )

    # Check if dependencies are installed, and install if necessary
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Dependency '$dep' not found, attempting to install..."
            if [[ -x "$(command -v apt-get)" ]]; then
                sudo apt-get install -y "$dep"
            elif [[ -x "$(command -v dnf)" ]]; then
                sudo dnf install -y "$dep"
            elif [[ -x "$(command -v pacman)" ]]; then
                sudo pacman -S --noconfirm "$dep"
            else
                echo "Unsupported package manager, please install '$dep' manually."
                exit 1
            fi
        fi
    done
}

# Download the tarball
download_aide() {
    echo "Downloading Aide from $download_url..."
    curl -L "$download_url" -o "/tmp/$tarball"
    if [[ $? -ne 0 ]]; then
        echo "Error downloading Aide. Exiting."
        exit 1
    fi
}

# Extract the tarball to the installation directory
extract_aide() {
    echo "Extracting Aide to $install_dir..."
    sudo mkdir -p "$install_dir"
    sudo tar -xzf "/tmp/$tarball" -C "$install_dir" --strip-components=1
}

# Set up desktop files and symbolic links
setup_desktop_files() {
    echo "Setting up desktop entries..."
    sudo cp "${_pkgname}-bin.desktop" /usr/share/applications/aide.desktop
    sudo cp "${_pkgname}-bin-url-handler.desktop" /usr/share/applications/aide-url-handler.desktop
    sudo chmod +x "$install_dir/bin/code"  # Make sure the main binary is executable
}

# Create a symbolic link for easy access
create_symlinks() {
    echo "Creating symbolic links..."
    sudo ln -s "$install_dir/bin/code" /usr/local/bin/aide
}

# Clean up temporary files
cleanup() {
    echo "Cleaning up..."
    rm -f "/tmp/$tarball"
}

# Main script execution
main() {
    # Fetch the latest version
    fetch_latest_version

    # Set tarball URL based on architecture
    set_tarball_url

    # Install dependencies
    install_dependencies

    # Download Aide
    download_aide

    # Extract Aide
    extract_aide

    # Set up desktop files and symlinks
    setup_desktop_files
    create_symlinks

    # Clean up temporary files
    cleanup

    echo "Aide installation completed!"
}

# Run the script
main
