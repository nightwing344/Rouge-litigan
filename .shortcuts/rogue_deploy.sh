#!/data/data/com.termux/files/usr/bin/bash
# RogueLitigan One-Click Deploy & Fetch APK

REPO="nightwing344/Rouge-litigan"
API="https://api.github.com/repos/$REPO"
APK_DIR="$HOME/storage/downloads"

# Set Git identity
git config --global user.name "nightwing344"
git config --global user.email "rkb344@gmail.com"

# Ask for token if not set
if [ -z "$GITHUB_TOKEN" ]; then
  read -sp "Enter your GitHub PAT: " GITHUB_TOKEN
  echo ""
fi
AUTH="Authorization: token $GITHUB_TOKEN"

echo "[*] Starting deploy..."

pkg install -y git curl jq wget >/dev/null 2>&1 || true

# Detect default branch (main vs master)
BRANCH=$(curl -s -H "$AUTH" "$API" | jq -r '.default_branch')
if [ -z "$BRANCH" ] || [ "$BRANCH" == "null" ]; then
  BRANCH="main"
fi
echo "[*] Using branch: $BRANCH"

# Setup Git remote if missing
if [ ! -d ".git" ]; then
  git init
  git checkout -b "$BRANCH"
  git remote add origin "https://$GITHUB_TOKEN@github.com/$REPO.git"
else
  git remote set-url origin "https://$GITHUB_TOKEN@github.com/$REPO.git"
fi

# Commit & push (with auto-pull to resolve conflicts)
git add .
git commit -m "Auto-deploy $(date '+%Y-%m-%d %H:%M:%S')" || echo "[*] Nothing new."
git pull origin $BRANCH --allow-unrelated-histories || true
git push origin $BRANCH

echo "[*] Code pushed. Waiting for GitHub Actions to finish..."

# Poll workflow status
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

# Download latest APK from release
APK_URL=$(curl -s -H "$AUTH" "$API/releases/latest" | jq -r '.assets[0].browser_download_url')

if [ -n "$APK_URL" ] && [ "$APK_URL" != "null" ]; then
  echo "[*] Downloading APK..."
  mkdir -p "$APK_DIR"
  wget -q --show-progress -O "$APK_DIR/RogueLitigan-latest.apk" "$APK_URL"
  echo "[*] APK saved to $APK_DIR/RogueLitigan-latest.apk"
else
  echo "[!] Could not find APK in latest release."
fi
