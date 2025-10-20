# dotfiles

Personal development environment setup with automated configuration management.

## Setup Script Usage

The `setup_dev_env.sh` script automates the installation and configuration of a complete development environment.

### Quick Start

```bash
# Make the script executable
chmod +x setup_dev_env.sh

# Run the setup
./setup_dev_env.sh
```

### Features

- **Interactive Installation**: Prompts for each application before installing
- **Backup System**: Automatically backs up existing configurations before overwriting
- **Idempotent**: Safe to run multiple times - skips already completed tasks
- **Error Handling**: Robust error handling with detailed logging
- **Network Verification**: Checks internet connectivity before downloads
- **Security**: Verifies downloaded scripts before execution

### What Gets Installed

**Core Tools:**
- Git with custom aliases
- Zsh with Oh My Zsh and Powerlevel10k theme
- Neovim
- WezTerm

**Optional Applications:**
- Visual Studio Code
- Joplin (note-taking app)
- Custom fonts

**Configurations:**
- Symlinks dotfiles from this repository
- Git configuration (name, email, aliases)
- Shell configuration
- Application-specific settings

### Logging & Monitoring

- All operations are logged to `~/setup_dev_env.log`
- Real-time progress feedback with colored output
- Backup location displayed if files are backed up

### Requirements

- **macOS**: Homebrew will be installed automatically
- **Linux**: Debian/Ubuntu with apt package manager
- **Internet connection** for downloading packages and scripts

### Troubleshooting

If the script fails:
1. Check the log file: `~/setup_dev_env.log`
2. Ensure you have internet connectivity
3. Verify you have sudo privileges for package installation
4. Check disk space for installations and backups

### Manual Cleanup

If you need to remove temporary files manually:
```bash
rm -f /tmp/install_ohmyzsh.sh /tmp/joplin_install.sh
```

### Backup Recovery

If you need to restore original configurations:
```bash
# Backup directory location is shown during script execution
# Example: ~/dotfiles_backup_2024-01-15_143022/
cp ~/dotfiles_backup_*/original_file ~/target_location
```
