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
- An Azure VM with **hibernation enabled** (see below)

## Azure VM Hibernation Requirements

The VM must support and have hibernation enabled. Key requirements:

**Supported VM sizes** (up to 64 GB RAM):
- Dasv5 / Dadsv5 / Dsv5 / Ddsv5 series
- Easv5 / Eadsv5 / Esv5 / Edsv5 series
- NVv4 / NVadsA10v5 series (GPU, preview)

**Requirements:**
- Hibernation must be **enabled at VM creation** (cannot be added to existing VMs without reconfiguration)
- OS disk must be large enough to hold the full RAM contents
- Windows page file cannot be on the temp disk

**Not supported with:**
- Ephemeral OS disks
- Shared disks
- Availability Sets
- Spot VMs
- Azure Backup

**Billing:** No compute charges while hibernated; storage/IPs still billed.

For full details, see the [Azure VM Hibernation documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/hibernate-resume).

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
