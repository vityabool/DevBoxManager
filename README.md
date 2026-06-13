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
- Azure CLI (`az`) configured with access to your VM
- Shell aliases/functions: `devbox-start`, `devbox-status`, `devbox-hibernate`, `devbox-ip`

## Build & Install

```bash
./build.sh
cp -r "build/DevBox Manager.app" /Applications/
```

## Start at Login

System Settings → General → Login Items → add "DevBox Manager"

Or via terminal:
```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/DevBox Manager.app", hidden:false}'
```
