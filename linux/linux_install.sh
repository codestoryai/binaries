#!/bin/bash

set -e

# Define variables
PKGNAME="aide"
PKGDIR="/opt/${PKGNAME}"
ARCH=$(uname -m)

# Function to fetch the latest release version from GitHub
fetch_latest_version() {
    echo "Fetching the latest Aide release version..."
    latest_release_info=$(curl -s https://api.github.com/repos/codestoryai/binaries/releases/latest)
    PKGVER=$(echo "$latest_release_info" | grep -Po '"tag_name": "\K[0-9.]+')
    if [[ -z "$PKGVER" ]]; then
        echo "Error: Unable to fetch the latest version."
        exit 1
    fi
    echo "Latest version: $PKGVER"
}

# Function to set the correct tarball URL based on architecture
set_tarball_url() {
    case "$ARCH" in
        x86_64)
            BIN_URL="https://github.com/codestoryai/binaries/releases/download/${PKGVER}/Aide-linux-x64-${PKGVER}.tar.gz"
            ;;
        aarch64)
            BIN_URL="https://github.com/codestoryai/binaries/releases/download/${PKGVER}/Aide-linux-arm64-${PKGVER}.tar.gz"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

# Check for and install required dependencies
check_dependencies() {
    echo "Checking for required dependencies..."

    dependencies=(
        "fontconfig"
        "libxtst"
        "gtk3"
        "python3"
        "cairo"
        "alsa-lib"
        "nss"
        "gcc"
        "libnotify"
        "libxss"
        "glibc"
        "bash"
    )

    missing_dependencies=()

    # Check each dependency with more targeted checks
    for dep in "${dependencies[@]}"; do
        case $dep in
            "glibc")
                # Check if `ldd` is available (often provided by glibc)
                if ! command -v ldd &>/dev/null; then
                    missing_dependencies+=("$dep")
                fi
                ;;
            "python3")
                # Check if `python3` command exists
                if ! command -v python3 &>/dev/null; then
                    missing_dependencies+=("$dep")
                fi
                ;;
            "gcc")
                # Check if `gcc` is available
                if ! command -v gcc &>/dev/null; then
                    missing_dependencies+=("$dep")
                fi
                ;;
            "bash")
                # Check if `bash` is available
                if ! command -v bash &>/dev/null; then
                    missing_dependencies+=("$dep")
                fi
                ;;
            *)
                # General check for libraries (e.g., fontconfig, libxtst)
                if ! ldconfig -p | grep -q "$dep"; then
                    missing_dependencies+=("$dep")
                fi
                ;;
        esac
    done

    # Report results
    if [ ${#missing_dependencies[@]} -eq 0 ]; then
        echo "All dependencies are satisfied. You're good to go!"
    else
        echo "The following dependencies are missing:"
        for dep in "${missing_dependencies[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Please install the missing dependencies and try again."
        echo "Note: Package names may differ across distributions, so you may need to look up the exact names for your system."
        exit 1
    fi
}

# Download and extract Aide
install_aide() {
    echo "Downloading Aide..."
    sudo mkdir -p "${PKGDIR}"
    sudo mkdir -p /usr/bin /usr/share/applications /usr/share/pixmaps
    curl -L "$BIN_URL" | sudo tar -xz -C "${PKGDIR}" --strip-components=1
}

# Create the aide launch script
create_launch_script() {
    sudo tee /usr/bin/aide > /dev/null << 'EOF'
#!/bin/bash
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}

if [[ -f $XDG_CONFIG_HOME/aide-flags.conf ]]; then
    readarray -t lines <"$XDG_CONFIG_HOME/aide-flags.conf"
    for line in "${lines[@]}"; do
        if ! [[ "$line" =~ ^[[:space:]]*# ]]; then
           CODE_USER_FLAGS+=($line)
        fi
    done
fi

exec /opt/aide/bin/aide "$@" "${CODE_USER_FLAGS[@]}"
EOF
    sudo chmod +x /usr/bin/aide
}

# Install the icon
install_icon() {
    sudo install -Dm644 "${PKGDIR}/resources/app/resources/linux/code.png" /usr/share/pixmaps/aide.png
}

# Create desktop entries
create_desktop_entries() {
    sudo tee /usr/share/applications/aide.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Aide
Comment=The Open-Source AI-native IDE.
GenericName=Text Editor
Exec=/usr/bin/aide %F
Icon=aide
Type=Application
StartupNotify=false
StartupWMClass=Aide
Categories=Utility;Development;IDE;
MimeType=text/plain;inode/directory;
Actions=new-empty-window;
Keywords=vscode;aide;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/bin/aide --new-window %F
Icon=aide
EOF

    sudo tee /usr/share/applications/aide-wayland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Aide - Wayland
Comment=The Open-Source AI-native IDE.
GenericName=Text Editor
Exec=/usr/bin/aide --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland %F
Icon=aide
Type=Application
StartupNotify=false
StartupWMClass=aide-url-handler
Categories=Utility;Development;IDE;
MimeType=text/plain;inode/directory;
Actions=new-empty-window;
Keywords=vscode;aide;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/bin/aide --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --new-window %F
Icon=aide
EOF

    sudo tee /usr/share/applications/aide-url-handler.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Aide - URL Handler
Comment=The Open-Source AI-native IDE.
GenericName=Text Editor
Exec=/usr/bin/aide --open-url %U
Icon=aide
Type=Application
NoDisplay=true
StartupNotify=false
Categories=Utility;TextEditor;Development;IDE;
MimeType=x-scheme-handler/aide;
Keywords=vscode;aide;
EOF
}

# Set permissions for chrome-sandbox
set_permissions() {
    sudo chown root "${PKGDIR}/chrome-sandbox"
    sudo chmod 4755 "${PKGDIR}/chrome-sandbox"
}

# Set up shell completions
setup_completions() {
    sudo mkdir -p /usr/share/zsh/site-functions /usr/share/bash-completion/completions
    sudo ln -sf "${PKGDIR}/resources/completions/zsh/_aide" /usr/share/zsh/site-functions/_aide
    sudo ln -sf "${PKGDIR}/resources/completions/bash/aide" /usr/share/bash-completion/completions/aide
}

# Main installation sequence
main() {
    fetch_latest_version
    set_tarball_url
    # check_dependencies
    install_aide
    create_launch_script
    install_icon
    create_desktop_entries
    set_permissions
    setup_completions

    echo "Aide installation complete."
    echo "Custom flags can be added to ~/.config/aide-flags.conf"
}

# Run the main function
main
