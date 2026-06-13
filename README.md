# DevBox Manager

A lightweight native macOS menu bar app for managing an Azure DevBox VM.

## Features

- 🖥️ Menu bar icon (no Dock presence)
- 📊 Live VM status from Azure (`devbox-status`)
- ⏱️ Uptime display with 5-hour warning notification
- 🌐 IP display with click-to-copy (`devbox-ip`)
- ▶ Start / ⏸ Hibernate controls
- 🔔 macOS notifications on actions and warnings
- ⌨️ Keyboard shortcuts: S (start), H (hibernate), R (refresh), Q (quit)

## Prerequisites

- macOS 12.0+
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3 with Pillow (`pip3 install Pillow`) — for icon generation
- Azure CLI (`az`) logged in (`az login`)

## Setup

### 1. Configure your Azure VM details

Edit `setup-shell.sh` and set your VM details at the top of the file:

```bash
DEVBOX_SUBSCRIPTION="YOUR_AZURE_SUBSCRIPTION_ID"  # Azure subscription ID (UUID)
DEVBOX_RG="YOUR_RESOURCE_GROUP"                    # Resource group containing the VM
DEVBOX_VM="YOUR_VM_NAME"                           # Name of the VM
```

You can find these values in the Azure Portal or by running:
```bash
az vm list -o table
```

### 2. Install shell commands

```bash
./setup-shell.sh
source ~/.zshrc
```

This adds the following commands to your shell:
- `devbox-start` — Start the VM
- `devbox-hibernate` — Hibernate the VM
- `devbox-status` — Show power state and uptime
- `devbox-ip` — Show the VM's public IP

### 3. Build & Install the app

```bash
./build.sh
cp -r "build/DevBox Manager.app" /Applications/
```

### 4. Start at Login (optional)

System Settings → General → Login Items → add "DevBox Manager"

Or via terminal:
```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/DevBox Manager.app", hidden:false}'
```
