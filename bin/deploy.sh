#!/bin/bash
set -euo pipefail

GITHUB_USER="didiator"
GITHUB_REPO="rasa-nlu"
GITHUB_TOKEN=$(grep 'token = ' ~/.gitconfig | awk '{print $3}')

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GITHUB_TOKEN not found!"
    exit 1
fi

CURRENT=$(cat VERSION 2>/dev/null || echo "0.1.0")
NEXT_VERSION="$(echo "$CURRENT" | awk -F. '{$NF+=1; print $1"."$2"."$NF}')"

set +e
read -t 10 -p "Version [Enter=v$NEXT_VERSION]: " INPUT
set -e
VERSION="${INPUT:-$NEXT_VERSION}"

echo "$VERSION" > VERSION
TAG="v$VERSION"

echo "=== STT Server Deployment: $TAG ==="

git add -A
git commit -m "Release $TAG" || true
git tag "$TAG"
git push origin main
git push origin "$TAG"

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases \
  -d "{\"tag_name\":\"$TAG\",\"name\":\"$TAG\"}"

echo "✅ Release created, monitoring Actions..."

for i in {1..36}; do
    sleep 5
    STATUS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/actions/runs?per_page=1" \
      | grep -o '"status": *"[^"]*"' | head -1 | sed 's/"status": *"\(.*\)"/\1/')
    
    [ "$STATUS" = "completed" ] && echo "✅ Deployed" && break
    [ $((i % 6)) -eq 0 ] && echo "   Deploying..."
done

PROD_VER=$(ssh PROD "cat ~/stt-server/VERSION 2>/dev/null" || echo "?")
echo "PROD: v$PROD_VER"
