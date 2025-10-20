#!/bin/bash
set -euo pipefail

# ==============================================================================
# Script to set up a software development environment.
#
# Version 3.0: Now with backup functionality.
#
# Features:
# - Asks before installing each application.
# - Backs up existing configurations before overwriting them.
# - Idempotent: Skips actions that are already completed.
# - Installs core tools, applications, and shell enhancements.
# - Symlinks dotfiles from a repository for easy management.
#
# Usage:
# 1. Save this script as 'setup_dev_env.sh'.
# 2. Grant execution permissions: chmod +x setup_dev_env.sh
# 3. Run it: ./setup_dev_env.sh
# ==============================================================================

# --- Configuration Variables ---
DOTFILES_REPO="https://github.com/instantfred/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
# This will be set on the first backup operation.
BACKUP_DIR=""
# Log file for tracking operations
LOG_FILE="$HOME/setup_dev_env.log"


# --- Utility Functions ---

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }

check_network() {
    info "Checking network connectivity..."
    if ! ping -c 1 google.com &> /dev/null && ! ping -c 1 8.8.8.8 &> /dev/null; then
        warning "No internet connection detected. Some operations may fail."
        return 1
    fi
    success "Network connectivity confirmed."
    return 0
}

cleanup() {
    log "Cleanup function called"
    if [[ -n "${TEMP_FILES:-}" ]]; then
        info "Cleaning up temporary files..."
        rm -f $TEMP_FILES 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

execute_with_error_handling() {
    local description="$1"
    shift
    log "Starting: $description"
    if "$@"; then
        log "Success: $description"
        return 0
    else
        log "Failed: $description"
        warning "Operation failed: $description"
        return 1
    fi
}

download_and_verify() {
    local url="$1"
    local output_file="$2"
    local expected_pattern="$3"
    
    log "Downloading script from: $url"
    
    if ! execute_with_error_handling "Download script from $url" curl -fsSL "$url" -o "$output_file"; then
        return 1
    fi
    
    # Basic verification - check if file contains expected pattern
    if [[ -n "$expected_pattern" ]] && ! grep -q "$expected_pattern" "$output_file"; then
        warning "Downloaded script does not contain expected pattern: $expected_pattern"
        rm -f "$output_file"
        return 1
    fi
    
    log "Script downloaded and verified: $output_file"
    return 0
}

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
prompt() {
    echo -e "\033[1;33m[QUESTION]\033[0m $1"
    read -p " (y/n) " -n 1 -r
    echo # Move to a new line
}

# --- System & Prerequisite Functions ---

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/debian_version ]; then PACKAGE_MANAGER="apt"; else
            warning "Unsupported package manager. Please install tools manually." && exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    else
        warning "Unsupported OS. Instructions for Windows: use Chocolatey or Winget." && exit 1
    fi
    info "Detected OS: $OS with $PACKAGE_MANAGER"
}

install_package_manager() {
    if [[ "$OS" == "macos" ]] && ! command -v brew &> /dev/null; then
        info "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        success "Homebrew has been installed."
    fi
}

# --- Core Component & Application Installation ---

clone_dotfiles_repo() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        info "Cloning dotfiles repository to make configurations available..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        success "Repository cloned into $DOTFILES_DIR."
    else
        info "Dotfiles directory already exists. Pulling latest changes..."
        (cd "$DOTFILES_DIR" && git pull)
        success "Repository updated."
    fi
}

install_fonts() {
    if [ ! -d "$DOTFILES_DIR/fonts" ]; then
        info "No 'fonts' directory found in dotfiles. Skipping font installation."
        return
    fi
    prompt "Install custom fonts?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing custom fonts..."
        local FONT_DIR
        if [[ "$OS" == "macos" ]]; then FONT_DIR="$HOME/Library/Fonts"; else
            FONT_DIR="$HOME/.local/share/fonts"
            mkdir -p "$FONT_DIR"
        fi
        cp -r "$DOTFILES_DIR/fonts/"* "$FONT_DIR/"
        if [[ "$OS" == "linux" ]] && command -v fc-cache &> /dev/null; then
            info "Updating font cache..." && fc-cache -f -v
        fi
        success "Custom fonts installed."
    fi
}

install_package() {
    local package_name=$1
    local command_to_check=$2
    
    if ! command -v "$command_to_check" &> /dev/null; then
        log "Installing package: $package_name"
        info "Installing $package_name..."
        
        if execute_with_error_handling "Install $package_name" bash -c "
            if [ '$PACKAGE_MANAGER' == 'brew' ]; then 
                brew install '$package_name'
            else 
                sudo apt-get update && sudo apt-get install -y '$package_name'
            fi
        "; then
            success "$package_name has been installed."
        else
            warning "Failed to install $package_name. Continuing with other installations."
            return 1
        fi
    else
        success "$package_name is already installed."
    fi
}

install_vscode_linux() {
    log "Starting VS Code installation for Linux"
    
    # Step 1: Install prerequisites
    if ! execute_with_error_handling "Install VS Code prerequisites" sudo apt-get install -y wget gpg; then
        warning "Failed to install prerequisites for VS Code"
        return 1
    fi
    
    # Step 2: Add Microsoft GPG key
    if ! execute_with_error_handling "Add Microsoft GPG key" bash -c '
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg &&
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg &&
        rm -f /tmp/packages.microsoft.gpg
    '; then
        warning "Failed to add Microsoft GPG key"
        return 1
    fi
    
    # Step 3: Add repository
    if ! execute_with_error_handling "Add VS Code repository" sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'; then
        warning "Failed to add VS Code repository"
        return 1
    fi
    
    # Step 4: Install transport and update
    if ! execute_with_error_handling "Update package lists" bash -c 'sudo apt-get install -y apt-transport-https && sudo apt-get update'; then
        warning "Failed to update package lists"
        return 1
    fi
    
    # Step 5: Install VS Code
    execute_with_error_handling "Install VS Code package" sudo apt-get install -y code
}

install_applications() {
    info "Now you can choose which applications to install."
    
    prompt "Install Neovim?" && [[ $REPLY =~ ^[Yy]$ ]] && install_package "neovim" "nvim"
    prompt "Install WezTerm?" && [[ $REPLY =~ ^[Yy]$ ]] && install_package "wezterm" "wezterm"
    
    prompt "Install Visual Studio Code?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v code &> /dev/null; then
            info "Installing Visual Studio Code..."
            if [[ "$OS" == "macos" ]]; then
                execute_with_error_handling "Install VS Code for macOS" brew install --cask visual-studio-code
            else
                install_vscode_linux
            fi
            if command -v code &> /dev/null; then
                success "VS Code has been installed."
            else
                warning "VS Code installation may have failed. Please check manually."
            fi
        else 
            success "VS Code is already installed."
        fi
    fi
    
    prompt "Install Joplin (note-taking app)?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local joplin_installed=false
        if [[ "$OS" == "linux" && -f "$HOME/.joplin/Joplin.AppImage" ]] || [[ "$OS" == "macos" && -d "/Applications/Joplin.app" ]]; then 
            joplin_installed=true
        fi
        
        if $joplin_installed; then 
            success "Joplin is already installed."
        else
            info "Installing Joplin..."
            local joplin_script="/tmp/joplin_install.sh"
            TEMP_FILES="${TEMP_FILES:-} $joplin_script"
            
            if download_and_verify "https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh" "$joplin_script" "Joplin"; then
                if execute_with_error_handling "Install Joplin" bash "$joplin_script"; then
                    success "Joplin has been installed."
                else
                    warning "Joplin installation failed."
                fi
                rm -f "$joplin_script"
            else
                warning "Failed to download Joplin installer."
            fi
        fi
    fi
}

# --- Configuration and Symlinking Functions ---

configure_zsh() {
    install_package "zsh" "zsh"
    
    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        prompt "Install Oh My Zsh?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local omz_script="/tmp/install_ohmyzsh.sh"
            TEMP_FILES="${TEMP_FILES:-} $omz_script"
            
            if download_and_verify "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$omz_script" "oh-my-zsh"; then
                if execute_with_error_handling "Install Oh My Zsh" bash "$omz_script" "" --unattended; then
                    success "Oh My Zsh installed."
                else
                    warning "Oh My Zsh installation failed."
                fi
                rm -f "$omz_script"
            else
                warning "Failed to download Oh My Zsh installer."
            fi
        fi
    else 
        success "Oh My Zsh is already installed."
    fi
    
    # Powerlevel10k
    local p10k_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [ ! -d "$p10k_dir" ]; then
        prompt "Install Powerlevel10k theme?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if execute_with_error_handling "Install Powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"; then
                success "P10k installed."
            else
                warning "Powerlevel10k installation failed."
            fi
        fi
    else 
        success "Powerlevel10k is already installed."
    fi
    
    # Change Shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        prompt "Change default shell to Zsh?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if execute_with_error_handling "Change default shell to zsh" chsh -s "$(which zsh)"; then
                success "Default shell changed to Zsh. Please log out and back in."
            else
                warning "Could not change shell automatically. Run: chsh -s $(which zsh)"
            fi
        fi
    else 
        success "Zsh is already your default shell."
    fi
}

configure_git() {
    info "Git configuration options:"
    
    prompt "Configure Git name?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your name for Git: " git_name
        git config --global user.name "$git_name"
        success "Git name configured."
    fi
    
    prompt "Configure Git email?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your email for Git: " git_email
        git config --global user.email "$git_email"
        success "Git email configured."
    fi
    
    prompt "Set default branch to 'main'?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git config --global init.defaultBranch main
        success "Default branch set to 'main'."
    fi
    
    if [ -f "$DOTFILES_DIR/git/.gitconfig_aliases" ]; then
        prompt "Apply Git aliases from dotfiles?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git config --global include.path "$DOTFILES_DIR/git/.gitconfig_aliases"
            success "Git aliases applied."
        fi
    fi
}

validate_backup_permissions() {
    local dest_path=$1
    if [ ! -w "$(dirname "$dest_path")" ]; then
        warning "No write permission for $(dirname "$dest_path"). Cannot create backup."
        return 1
    fi
    if [ -e "$dest_path" ] && [ ! -w "$dest_path" ]; then
        warning "No write permission for $dest_path. Cannot backup file."
        return 1
    fi
    return 0
}

# The new, smarter symlinking function with backups.
link_file() {
    local source_path=$1
    local dest_path=$2
    local dest_dir=$(dirname "$dest_path")

    log "Attempting to link: $source_path -> $dest_path"
    
    # Ensure the parent directory of the destination exists
    mkdir -p "$dest_dir" || {
        warning "Failed to create directory $dest_dir"
        return 1
    }

    # Check if destination exists and is not already the correct symlink
    if [ -e "$dest_path" ] && [ "$(readlink "$dest_path")" != "$source_path" ]; then
        if ! validate_backup_permissions "$dest_path"; then
            warning "Skipping $dest_path due to permission issues."
            return 1
        fi
        
        prompt "Configuration already exists at $dest_path. Overwrite and back up the original?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create the single backup directory if it hasn't been created yet
            if [ -z "$BACKUP_DIR" ]; then
                BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y-%m-%d_%H%M%S)"
                if ! mkdir -p "$BACKUP_DIR"; then
                    warning "Failed to create backup directory. Skipping backup."
                    return 1
                fi
                info "Created backup directory at $BACKUP_DIR"
                log "Backup directory created: $BACKUP_DIR"
            fi
            
            info "Backing up $dest_path..."
            if mv "$dest_path" "$BACKUP_DIR/"; then
                log "Successfully backed up: $dest_path"
            else
                warning "Failed to backup $dest_path"
                return 1
            fi
            
            info "Creating new symlink for $dest_path..."
            if ln -snf "$source_path" "$dest_path"; then
                success "Linked $dest_path."
                log "Successfully linked: $dest_path"
            else
                warning "Failed to create symlink for $dest_path"
                return 1
            fi
        else
            info "Skipping $dest_path."
            log "User skipped linking: $dest_path"
        fi
    elif [ ! -e "$dest_path" ]; then
        # Destination does not exist, just link it
        info "Linking $dest_path..."
        if ln -sn "$source_path" "$dest_path"; then
            success "Linked $dest_path."
            log "Successfully linked new file: $dest_path"
        else
            warning "Failed to create symlink for $dest_path"
            return 1
        fi
    else
        # Destination is already correctly linked
        success "$dest_path is already linked correctly."
        log "File already correctly linked: $dest_path"
    fi
}

setup_symlinks() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        warning "Dotfiles directory not found. Skipping symbolic link creation."
        return
    fi
    
    info "Checking for existing configurations to link..."

    # Link all configurations using the new helper function
    link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    link_file "$DOTFILES_DIR/wezterm" "$HOME/.config/wezterm"
    
    if [ -d "$DOTFILES_DIR/joplin" ]; then
        link_file "$DOTFILES_DIR/joplin/userchrome.css" "$HOME/.config/joplin-desktop/userchrome.css"
        link_file "$DOTFILES_DIR/joplin/userstyle.css" "$HOME/.config/joplin-desktop/userstyle.css"
    fi

    # If backups were made, show a final confirmation message.
    if [ -n "$BACKUP_DIR" ]; then
        success "All original files were backed up to: $BACKUP_DIR"
    fi
}

# --- Main Script Flow ---

main() {
    log "=== Development Environment Setup Started ==="
    info "Starting development environment setup."
    
    detect_os
    check_network || warning "Limited network connectivity - some installations may fail"
    install_package_manager

    install_package "git" "git"
    clone_dotfiles_repo

    install_fonts
    install_applications
    
    configure_zsh
    configure_git

    # The final step is to link all the configurations
    setup_symlinks
    
    log "=== Development Environment Setup Completed ==="
    success "Setup complete!"
    info "Please restart your terminal or log out and back in to apply all changes."
    info "Installation log saved to: $LOG_FILE"
}

main