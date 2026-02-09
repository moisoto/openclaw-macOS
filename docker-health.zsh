#!/usr/bin/env zsh
set -euo pipefail

REPO_FOLDER="openclaw"

if [[ ! -d $REPO_FOLDER ]]; then
  echo "OpenClaw repository not found!"
  exit 1
fi

cd $REPO_FOLDER
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Not inside a git repository"
}

if [[ $(pwd) != "$repo_root" ]]; then
  echo "Moving into root folder of the repository"
  cd "$repo_root"
fi

COMPOSE_FILE="docker-compose.yml"

echo
echo "==> Checking Health"

docker compose -f "$COMPOSE_FILE" exec openclaw-gateway node dist/index.js health
