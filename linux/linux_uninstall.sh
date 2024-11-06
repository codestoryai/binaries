#!/bin/bash

set -e

# Define variables
PKGNAME="aide"
PKGDIR="/opt/${PKGNAME}"

# Remove Aide files and directories
remove_aide_files() {
    echo "Removing Aide files..."
    sudo rm -rf "${PKGDIR}"
}

# Remove the launch script
remove_launch_script() {
    echo "Removing the launch script..."
    sudo rm -f /usr/bin/aide
}

# Remove the application icon
remove_icon() {
    echo "Removing the application icon..."
    sudo rm -f /usr/share/pixmaps/aide.png
}

# Remove the desktop entries
remove_desktop_entries() {
    echo "Removing desktop entries..."
    sudo rm -f /usr/share/applications/aide.desktop
    sudo rm -f /usr/share/applications/aide-wayland.desktop
    sudo rm -f /usr/share/applications/aide-url-handler.desktop
}

# Remove the chrome-sandbox permissions
remove_permissions() {
    echo "Removing chrome-sandbox permissions..."
    sudo rm -f "${PKGDIR}/chrome-sandbox"
}

# Remove shell completions
remove_completions() {
    echo "Removing shell completions..."
    sudo rm -f /usr/share/zsh/site-functions/_aide
    sudo rm -f /usr/share/bash-completion/completions/aide
}

# Main uninstallation sequence
main() {
    remove_aide_files
    remove_launch_script
    remove_icon
    remove_desktop_entries
    remove_permissions
    remove_completions

    echo "Aide uninstallation complete."
    echo "The dependencies were not removed."
}

# Run the main function
main
