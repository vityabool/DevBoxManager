#!/bin/bash
# DevBox Manager - Shell commands setup
# This script adds the required shell functions/aliases to your .zshrc
#
# Before running, set your Azure VM details below:

DEVBOX_SUBSCRIPTION="YOUR_AZURE_SUBSCRIPTION_ID"
DEVBOX_RG="YOUR_RESOURCE_GROUP"
DEVBOX_VM="YOUR_VM_NAME"

set -euo pipefail

ZSHRC="$HOME/.zshrc"

# Check if already configured
if grep -q "DEVBOX_SUBSCRIPTION" "$ZSHRC" 2>/dev/null; then
    echo "⚠️  DevBox configuration already exists in $ZSHRC"
    echo "   Edit it manually or remove the existing block first."
    exit 1
fi

cat >> "$ZSHRC" << 'DEVBOX_BLOCK'

# === DevBox Manager ===
DEVBOX_BLOCK

cat >> "$ZSHRC" << DEVBOX_VARS
export DEVBOX_SUBSCRIPTION="$DEVBOX_SUBSCRIPTION"
export DEVBOX_RG="$DEVBOX_RG"
export DEVBOX_VM="$DEVBOX_VM"
DEVBOX_VARS

cat >> "$ZSHRC" << 'DEVBOX_FUNCS'

alias devbox-start='az account set --subscription "$DEVBOX_SUBSCRIPTION" && az vm start -g "$DEVBOX_RG" -n "$DEVBOX_VM"'
alias devbox-hibernate='az account set --subscription "$DEVBOX_SUBSCRIPTION" && az vm deallocate -g "$DEVBOX_RG" -n "$DEVBOX_VM" --hibernate true'
alias devbox-ip='az account set --subscription "$DEVBOX_SUBSCRIPTION" && az vm list-ip-addresses -g "$DEVBOX_RG" -n "$DEVBOX_VM" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv'

devbox-status() {
  az account set --subscription "$DEVBOX_SUBSCRIPTION"
  local _db_json
  _db_json=$(az vm get-instance-view -g "$DEVBOX_RG" -n "$DEVBOX_VM" \
    --query "instanceView.statuses[]" \
    -o json 2>/dev/null)

  python3 -c "
import sys, json
from datetime import datetime, timezone

data = json.loads('''$_db_json''')
power = next((s['displayStatus'] for s in data if s['code'].startswith('PowerState/')), 'Unknown')
print(power)

if power == 'VM running':
    prov = next((s.get('time','') for s in data if s['code'].startswith('ProvisioningState/')), '')
    if prov:
        start = datetime.fromisoformat(prov.replace('Z','+00:00'))
        delta = datetime.now(timezone.utc) - start
        h = int(delta.total_seconds()) // 3600
        m = (int(delta.total_seconds()) % 3600) // 60
        print(f'Uptime: {h}h {m}m')
" 2>/dev/null
}
# === End DevBox Manager ===
DEVBOX_FUNCS

echo "✅ DevBox shell commands added to $ZSHRC"
echo "   Run: source $ZSHRC"
