#!/usr/bin/env zsh
set -e

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository"
  exit 1
}

# Make sure we are on the repo root folder
if [[ "$repo_root" != "$(pwd)" ]]; then
  echo "Not in repo root. Moving into it."
  cd "$repo_root" || exit 1
fi

submodule="openclaw"
cd $submodule

# Remember current commit
BEFORE=$(git rev-parse HEAD)

echo "Updating submodule: $submodule"
git pull --ff-only

# Check if HEAD changed
AFTER=$(git rev-parse HEAD)

cd - >/dev/null

if [[ "$BEFORE" != "$AFTER" ]]; then
  echo
  echo "Submodule updated, committing in parent repo"
  git add $submodule
  git commit -m "Update submodule $submodule"
  echo
  echo '/----------------------------------------------------------\'
  echo '| Remember to test everything before pushing to the remote |'
  echo '\----------------------------------------------------------/'
else
  echo "No changes pulled, nothing to commit"
fi
