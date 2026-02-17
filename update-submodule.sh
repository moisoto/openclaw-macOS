#!/usr/bin/env zsh
set -euo pipefail

# Setup Term Colors
MC_BLUE="\033[38;5;117m"
MC_YELLOW="\033[38;5;229m"
TC_GREEN="\033[38;5;79m"
MC_NORMAL="\033[0m"

# Flag: Skip submodule update
PROCEED="no"

# Flag: Reset to Commit of Latest Tag
LATEST_TAG="yes"

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository"
  exit 1
}

submodule="openclaw"

if [[ ! -d "$submodule" ]]; then
  echo "Submodule folder not found."
  exit 1
fi
cd $submodule

chk-submodule-pending() {
  if ! git diff --quiet --submodule=log -- "$submodule"; then
    echo "${MC_YELLOW}Your submodule commits are not tracked in the main repo.${MC_NORMAL}"
    read "REPLY?Do you want to commit submodule to main repo? [y/N] "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      git add $submodule
      git commit -m "Update submodule $submodule"
      echo "${TC_GREEN}Submodule Committed to Main Repo.${MC_NORMAL}"
    else
      echo "Submodule commit to main repo skipped."
    fi
  fi
}

# Make sure we have up-to-date remote info
echo "Fetching Submodule..."
git fetch origin main >/dev/null 2>&1

# Fetch tags
echo "Fetching Tags..."
git fetch origin --tags >/dev/null 2>&1

# Get "latest" tag
last_tag=$(git describe --tags --abbrev=0 origin/main)

# Get commit hashes
echo "Getting Hashes..."
local_head=$(git rev-parse main)
remote_head=$(git rev-parse origin/main)
merge_base=$(git merge-base main origin/main)
latest_tag_commit=$(git rev-parse "$last_tag^{}")
latest_base=$(git merge-base "$local_head" "$latest_tag_commit")

if [[ "$local_head" == "$latest_tag_commit" && "$LATEST_TAG" == "yes" ]]; then
  echo
  echo "${TC_GREEN}Submodule at latest tag (${MC_BLUE}$last_tag${TC_GREEN}).${MC_NORMAL}"
  echo "No need to update."
  cd - >/dev/null
  chk-submodule-pending
  exit 0
elif [[ "$latest_tag_commit" == "$latest_base" && "$LATEST_TAG" == "yes" ]]; then
  echo
  echo "${MC_YELLOW}Submodule is past the latest tag (${MC_BLUE}$last_tag${MC_YELLOW})!${MC_NORMAL}"
  read "REPLY?Do you want discard extra commits? [y/N] "
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    git reset --hard "$latest_tag_commit"
    echo "${TC_GREEN}Submodule now at latest tag.${MC_NORMAL}"
    cd - >/dev/null
    chk-submodule-pending
    exit 0
  else
    echo "Nothing Reset."
  fi
fi

echo
if [[ "$local_head" == "$remote_head" ]]; then
  echo "${TC_GREEN}Submodule is already up to date.${MC_NORMAL}"
  exit 0
elif [[ "$local_head" == "$merge_base" ]]; then
  echo "${MC_YELLOW}Submodule is behind origin/main${MC_NORMAL}"
  read "REPLY?Do you want to update submodule $submodule? [y/N] "

  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    PROCEED="yes"
  fi
elif [[ "$remote_head" == "$merge_base" ]]; then
  echo "Unexpected State: main is ahead of origin/main"
  exit 2
else
  echo "Unexpected State: main and origin/main have diverged"
  exit 3
fi

echo
if [[ $PROCEED == "yes" ]]; then
  # Remember current commit
  BEFORE=$(git rev-parse HEAD)

  echo "Updating submodule: $submodule"
  git pull --ff-only

  # Check if HEAD changed
  AFTER=$(git rev-parse HEAD)

  # Fetching Hashes
  local_head="$AFTER"
  latest_tag_commit=$(git rev-parse "$last_tag^{}")

  # Update Latest Base in respect to latest tag
  latest_base=$(git merge-base "$local_head" "$latest_tag_commit")

  if [[ "$BEFORE" != "$AFTER" ]]; then
    echo
    if [[ "$latest_tag_commit" == "$latest_base" && "$LATEST_TAG" == "yes" ]]; then
      echo "${MC_YELLOW}Our pull went past the latest tag (${MC_BLUE}$last_tag${MC_YELLOW})! Extra commits will be discarded.${MC_NORMAL}"
      git reset --hard "$latest_tag_commit"
      echo "Submodule now at latest tag"
      echo
    fi
    echo "${MC_BLUE}Submodule updated.${MC_NORMAL}"
    read "REPLY?Do you want to commit submodule to main repo? [y/N] "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      cd - >/dev/null
      git add $submodule
      git commit -m "Update submodule $submodule"
      echo "Submodule Committed."
    else
      echo "${MC_YELLOW}Skipped Submodule Commit.${MC_NORMAL}"
    fi
    echo
    echo '/----------------------------------------------------------\'
    echo '| Remember to test everything before pushing to the remote |'
    echo '\----------------------------------------------------------/'
  else
    echo "No changes pulled, nothing to commit"
  fi
else
  echo "Submodule not updated!"
  cd - >/dev/null
  chk-submodule-pending
fi
