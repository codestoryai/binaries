#!/bin/bash

# Aide Uninstallation Script for All Linux Distros
# Ensure the script is run with sudo privileges

# Variables
_pkgname="aide"
install_dir="/opt/aide"
desktop_files=(
    "/usr/share/applications/aide.desktop"
    "/usr/share/applications/aide-url-handler.desktop"
)
symlink="/usr/local/bin/aide"

# Function to remove installation directory
remove_installation_directory() {
    if [[ -d "$install_dir" ]]; then
        echo "Removing Aide installation directory at $install_dir..."
        sudo rm -rf "$install_dir"
    else
        echo "Installation directory not found at $install_dir."
    fi
}

# Function to remove desktop entries
remove_desktop_files() {
    echo "Removing desktop entries..."
    for file in "${desktop_files[@]}"; do
        if [[ -f "$file" ]]; then
            sudo rm -f "$file"
            echo "Removed $file"
        else
            echo "Desktop file $file not found."
        fi
    done
}

# Function to remove symbolic links
remove_symlinks() {
    if [[ -L "$symlink" ]]; then
        echo "Removing symbolic link at $symlink..."
        sudo rm -f "$symlink"
    else
        echo "Symbolic link $symlink not found."
    fi
}

# Main script execution
main() {
    echo "Starting Aide uninstallation..."

    # Remove installation directory
    remove_installation_directory

    # Remove desktop files
    remove_desktop_files

    # Remove symbolic link
    remove_symlinks

    echo "Aide uninstallation completed!"
}

# Run the script
main
