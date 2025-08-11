#!/bin/bash

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

# --- Utility Functions ---

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
        info "Installing $package_name..."
        if [ "$PACKAGE_MANAGER" == "brew" ]; then brew install "$package_name"; else
            sudo apt-get update && sudo apt-get install -y "$package_name"
        fi
        success "$package_name has been installed."
    else
        success "$package_name is already installed."
    fi
}

install_applications() {
    info "Now you can choose which applications to install."
    
    prompt "Install Neovim?" && [[ $REPLY =~ ^[Yy]$ ]] && install_package "neovim" "nvim"
    prompt "Install WezTerm?" && [[ $REPLY =~ ^[Yy]$ ]] && install_package "wezterm" "wezterm"
    
    prompt "Install Visual Studio Code?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v code &> /dev/null; then
            info "Installing Visual Studio Code..."
            if [[ "$OS" == "macos" ]]; then brew install --cask visual-studio-code; else
                sudo apt-get install wget gpg -y && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && rm -f packages.microsoft.gpg && sudo apt-get install apt-transport-https -y && sudo apt-get update && sudo apt-get install code -y
            fi
            success "VS Code has been installed."
        else success "VS Code is already installed."; fi
    fi
    
    prompt "Install Joplin (note-taking app)?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local joplin_installed=false
        if [[ "$OS" == "linux" && -f "$HOME/.joplin/Joplin.AppImage" ]] || [[ "$OS" == "macos" && -d "/Applications/Joplin.app" ]]; then joplin_installed=true; fi
        if $joplin_installed; then success "Joplin is already installed."; else
            info "Installing Joplin..."
            wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
            success "Joplin has been installed."
        fi
    fi
}

# --- Configuration and Symlinking Functions ---

configure_zsh() {
    install_package "zsh" "zsh"
    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        prompt "Install Oh My Zsh?" && [[ $REPLY =~ ^[Yy]$ ]] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && success "Oh My Zsh installed."
    else success "Oh My Zsh is already installed."; fi
    # Powerlevel10k
    local p10k_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    if [ ! -d "$p10k_dir" ]; then
        prompt "Install Powerlevel10k theme?" && [[ $REPLY =~ ^[Yy]$ ]] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" && success "P10k installed."
    else success "Powerlevel10k is already installed."; fi
    # Change Shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        prompt "Change default shell to Zsh?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if chsh -s "$(which zsh)"; then success "Default shell changed to Zsh. Please log out and back in."; else warning "Could not change shell automatically."; fi
        fi
    else success "Zsh is already your default shell."; fi
}

configure_git() {
    prompt "Configure Git (name, email, and aliases)?"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Configuring Git..."
        read -p "Enter your name for Git: " git_name
        read -p "Enter your email for Git: " git_email
        git config --global user.name "$git_name" && git config --global user.email "$git_email" && git config --global init.defaultBranch main
        if [ -f "$DOTFILES_DIR/git/.gitconfig_aliases" ]; then
            info "Applying Git aliases..." && git config --global include.path "$DOTFILES_DIR/git/.gitconfig_aliases"
        fi
        success "Git configured."
    fi
}

# The new, smarter symlinking function with backups.
link_file() {
    local source_path=$1
    local dest_path=$2
    local dest_dir=$(dirname "$dest_path")

    # Ensure the parent directory of the destination exists
    mkdir -p "$dest_dir"

    # Check if destination exists and is not already the correct symlink
    if [ -e "$dest_path" ] && [ "$(readlink "$dest_path")" != "$source_path" ]; then
        prompt "Configuration already exists at $dest_path. Overwrite and back up the original?"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create the single backup directory if it hasn't been created yet
            if [ -z "$BACKUP_DIR" ]; then
                BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y-%m-%d_%H%M%S)"
                mkdir -p "$BACKUP_DIR"
                info "Created backup directory at $BACKUP_DIR"
            fi
            
            info "Backing up $dest_path..."
            mv "$dest_path" "$BACKUP_DIR/"
            
            info "Creating new symlink for $dest_path..."
            ln -snf "$source_path" "$dest_path"
            success "Linked $dest_path."
        else
            info "Skipping $dest_path."
        fi
    elif [ ! -e "$dest_path" ]; then
        # Destination does not exist, just link it
        info "Linking $dest_path..."
        ln -sn "$source_path" "$dest_path"
        success "Linked $dest_path."
    else
        # Destination is already correctly linked
        success "$dest_path is already linked correctly."
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
    info "Starting development environment setup."
    detect_os
    install_package_manager

    install_package "git" "git"
    clone_dotfiles_repo

    install_fonts
    install_applications
    
    configure_zsh
    configure_git

    # The final step is to link all the configurations
    setup_symlinks
    
    success "Setup complete!"
    info "Please restart your terminal or log out and back in to apply all changes."
}

main