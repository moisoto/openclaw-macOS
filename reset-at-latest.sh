#!/usr/bin/env zsh
set -euo pipefail

# Setup Term Colors
MC_BLUE="\033[38;5;117m"
MC_YELLOW="\033[38;5;229m"
TC_GREEN="\033[38;5;79m"
MC_NORMAL="\033[0m"

submodule="openclaw"

if [[ ! -d $submodule ]]; then
  echo "Submodule $submodule not found."
  exit 1
fi

cd $submodule
echo "Fetching..."
git fetch origin main >/dev/null 2>&1
git fetch origin --tags >/dev/null 2>&1

# Get latest stable tag in repository
# Excludes prerelease tags like beta/rc/alpha
last_tag=$(
  git tag --sort=-v:refname \
    | grep -Ev 'beta|rc|alpha' \
    | head -n1
)

# Fallback:
# If no stable tag exists, use nearest reachable tag from origin/main
if [[ -z "$last_tag" ]]; then
  last_tag=$(git describe --tags --abbrev=0 origin/main)
fi

# Get current local tag
curr_tag=$(git tag --points-at HEAD)

[[ "$curr_tag" == "$last_tag" ]] && MSG_COLOR=$TC_GREEN || MSG_COLOR=$MC_YELLOW
[[ ! -z "$curr_tag" ]] && echo "${MSG_COLOR}Current Local Tag: ${curr_tag}${MC_NORMAL}"
[[ ! -z "$last_tag" ]] && echo "${TC_GREEN}Latest Remote Tag: ${last_tag}${MC_NORMAL}"

if [[ ! "$curr_tag" == "$last_tag" ]]; then
  HASH=$(git rev-parse "$last_tag^{}")
  echo "Discarding everything past hash $HASH!"

  read "REPLY?Do you wish to continue? [y/N] "
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    # Reset HEAD, the index, and all tracked files
    # to exactly match the specified commit
    git reset --hard "$HASH"

    # Remove all untracked files and directories
    # (files that did not exist at that commit)
    git clean -fd

    echo "${MC_BLUE}Submodule updated.${MC_NORMAL}"
    read "REPLY?Do you want to commit submodule to main repo? [y/N] "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      cd - >/dev/null
      git add $submodule
      git commit -m "Update submodule $submodule"
      echo "Submodule Committed."
    else
      echo "${MC_YELLOW}Submodule Commit skipped.${MC_NORMAL}"
    fi
  else
    echo "Submodule Reset skipped."
  fi
else
  echo "Everything's fine"
fi
