#!/bin/bash
# GitHub Actions Secrets Configuration Script
# 
# Da der self-hosted Runner als User 'dgl' läuft und bereits
# SSH-Config für PROD hat (~/.ssh/config), sind explizite Secrets
# nicht zwingend erforderlich. Dieses Skript ist für Dokumentation
# und falls der Runner auf einem anderen System läuft.

set -euo pipefail

GITHUB_USER="didiator"
GITHUB_TOKEN=$(grep 'token = ' ~/.gitconfig | awk '{print $3}')

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN not found in ~/.gitconfig"
    exit 1
fi

# Funktion zum Verschlüsseln und Hinzufügen eines Secrets
add_secret() {
    local repo=$1
    local secret_name=$2
    local secret_value=$3
    
    # Hole Public Key für Verschlüsselung
    response=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_USER/$repo/actions/secrets/public-key")
    
    key_id=$(echo "$response" | grep -o '"key_id": *"[^"]*"' | sed 's/"key_id": *"\(.*\)"/\1/')
    public_key=$(echo "$response" | grep -o '"key": *"[^"]*"' | sed 's/"key": *"\(.*\)"/\1/')
    
    if [ -z "$key_id" ] || [ -z "$public_key" ]; then
        echo "  ❌ Failed to get public key for $repo"
        return 1
    fi
    
    # Für echte Verschlüsselung würde man hier libsodium verwenden
    # Da der Runner aber lokal läuft, ist das nicht kritisch
    echo "  ⚠️  Secret $secret_name für $repo kann nur via Web UI oder mit libsodium gesetzt werden"
    echo "     https://github.com/$GITHUB_USER/$repo/settings/secrets/actions"
}

echo "=== GitHub Actions Secrets Setup ==="
echo ""
echo "HINWEIS: Self-hosted Runner läuft als User 'dgl' und hat bereits:"
echo "  - SSH Config: Host PROD → 192.168.2.1"
echo "  - SSH Key: ~/.ssh/github_prod"
echo ""
echo "Secrets sind optional, aber für Vollständigkeit dokumentiert:"
echo ""

for repo in rasa-nlu stt-server; do
    echo "Repository: $repo"
    add_secret "$repo" "PROD_HOST" "192.168.2.1"
    add_secret "$repo" "PROD_USER" "dgl"
    echo ""
done

echo "=== Manuelle Secret-Konfiguration ==="
echo ""
echo "Da GitHub Secrets Verschlüsselung mit libsodium benötigt,"
echo "können Sie die Secrets auch manuell über die Web-UI setzen:"
echo ""
echo "1. Rasa NLU:"
echo "   https://github.com/didiator/rasa-nlu/settings/secrets/actions"
echo ""
echo "2. STT Server:"
echo "   https://github.com/didiator/stt-server/settings/secrets/actions"
echo ""
echo "Secrets (optional):"
echo "  - PROD_HOST: 192.168.2.1"
echo "  - PROD_USER: dgl"
echo ""
echo "⚠️  WICHTIG: SSH-Key ~/.ssh/github_prod muss auf dem Runner verfügbar sein!"
