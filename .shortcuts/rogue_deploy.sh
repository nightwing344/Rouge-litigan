#!/data/data/com.termux/files/usr/bin/bash
# RogueLitigan One-Click Deploy & Fetch APK

REPO="nightwing344/Rouge-litigan"
BRANCH="main"   # change to "master" if your repo uses master
API="https://api.github.com/repos/$REPO"
APK_DIR="$HOME/storage/downloads"

# Set Git identity (so commits work without asking)
git config --global user.name "nightwing344"
git config --global user.email "rkb344@gmail.com"

# Ask for token if not set
if [ -z "$GITHUB_TOKEN" ]; then
  read -sp "Enter your GitHub PAT: " GITHUB_TOKEN
  echo ""
fi
AUTH="Authorization: token $GITHUB_TOKEN"

echo "[*] Starting deploy..."

# Ensure tools installed
pkg install -y git curl jq wget >/dev/null 2>&1 || true

# Setup Git remote
if [ ! -d ".git" ]; then
  git init
  git remote add origin "https://$GITHUB_TOKEN@github.com/$REPO.git"
  git checkout -b "$BRANCH"
else
  git remote set-url origin "https://$GITHUB_TOKEN@github.com/$REPO.git"
fi

# Commit & push
git add .
git commit -m "Auto-deploy $(date '+%Y-%m-%d %H:%M:%S')" || echo "[*] Nothing new."
git push origin "$BRANCH"

echo "[*] Code pushed. Waiting for GitHub Actions to finish..."

# Poll the latest workflow run
while true; do
  STATUS=$(curl -s -H "$AUTH" "$API/actions/runs?branch=$BRANCH&per_page=1" | jq -r '.workflow_runs[0].status')
  CONCLUSION=$(curl -s -H "$AUTH" "$API/actions/runs?branch=$BRANCH&per_page=1" | jq -r '.workflow_runs[0].conclusion')

  if [ "$STATUS" == "completed" ]; then
    if [ "$CONCLUSION" == "success" ]; then
      echo "[*] Build finished successfully."
      break
    else
      echo "[!] Build failed."
      exit 1
    fi
  fi

  echo "[*] Still running... checking again in 30s."
  sleep 30
done

# Grab latest release asset (APK)
APK_URL=$(curl -s -H "$AUTH" "$API/releases/latest" | jq -r '.assets[0].browser_download_url')

if [ -n "$APK_URL" ] && [ "$APK_URL" != "null" ]; then
  echo "[*] Downloading APK..."
  mkdir -p "$APK_DIR"
  wget -q --show-progress -O "$APK_DIR/RogueLitigan-latest.apk" "$APK_URL"
  echo "[*] APK saved to $APK_DIR/RogueLitigan-latest.apk"
else
  echo "[!] Could not find APK in latest release."
fi
