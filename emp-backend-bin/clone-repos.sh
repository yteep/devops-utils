#!/bin/bash

set -x

KEY_PATH="/opt/emp-manage/.keys"
KEY="emp-manage-backend-key"
REPO_URL="<Your GitHub Repo URL>"
REPO_NAME="emp-manage-backend"
REPO_BASE_PATH="/opt/emp-manage/repos"
REPO_DIR="$REPO_BASE_PATH/$REPO_NAME"


# Check if the key file exists
if [ ! -f "$KEY_PATH/$KEY" ]; then
  echo "Error: SSH key not found at $KEY_PATH"
  exit 1
fi

# Start ssh-agent if it's not running
if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
  eval "$(ssh-agent -s)"
fi

# Check if the key is already loaded
pub_key=$(ssh-keygen -y -f "$KEY_PATH/$KEY" 2>/dev/null)
if ssh-add -L 2>/dev/null | grep -qF "$pub_key"; then
  echo "SSH key already loaded."
else
  echo "Loading SSH key..."
  ssh-add "$KEY_PATH/$KEY" || { echo "Failed to add SSH key"; return 1; }
fi


# Clone the repo if not already present
mkdir -p "$REPO_BASE_PATH"

if [ -d "$REPO_DIR/.git" ]; then
  echo "Repository already exists at $REPO_DIR."
else
  echo "Cloning $REPO_URL into $REPO_DIR ..."
  git clone "$REPO_URL" "$REPO_DIR"
  echo "Clone complete."
fi
