#!/usr/bin/env zsh

option=$1
set -euo pipefail

repo_path="openclaw"

if [[ ! -d $repo_path ]]; then
  echo "Repo path not found."
  exit 1
fi

REF_FMT="%(align:18,left)%(refname:short)%(end)"
OTY_FMT="%(align:8,left)%(objecttype)%(end)"
CDT_FMT="%(creatordate:short)"
ONA_FMT="%(objectname:short=10)"
PLD_FMT="%(*objectname:short=10)"
HSH_FMT="%(align:width=23,position=left)$ONA_FMT%(if)%(taggerdate)%(then) → $PLD_FMT%(end)%(end)"
SUB_FMT="%(align:70,left)%(contents:subject)%(end)"
GUM_VAL="%(if)%(taggerdate)%(then)%(*objectname:short=10)%(else)%(objectname:short=10)%(end)"
GUM_LBL="$GUM_VAL → %(contents:subject)"

cd $repo_path
echo "Fetching..."
git fetch origin main >/dev/null 2>&1
git fetch origin --tags >/dev/null 2>&1

show_tags() {
echo "| Tag/Ref            | Type     | Date       | Hash                    | Subject                                                                |"
echo "|--------------------|----------|------------|-------------------------|------------------------------------------------------------------------|"
git for-each-ref refs/tags \
  --sort=-creatordate \
  --format="| $REF_FMT | $OTY_FMT | $CDT_FMT | $HSH_FMT | $SUB_FMT |" |
  head -10
}

printf "\033[38;5;117mLatest References (includes tags on remote):\033[0m"
if command -v glow >/dev/null 2>&1; then
  show_tags | glow -w0
else
  show_tags
fi

# Exit if --list was passed
if [[ "$option" == "--list" ]]; then
  exit 0
fi

if ! command -v glow >/dev/null 2>&1; then
  echo "gum utility is required to proceed with reset"
  exit 1
fi

HASH=$(\
  git for-each-ref refs/tags \
    --sort=-creatordate \
    --format="$GUM_LBL|$GUM_VAL" | \
  while IFS='|' read -r lbl val; do
    git merge-base --is-ancestor "$val" HEAD && \
      printf '%s|%s\n' "$lbl" "$val"
  done |
  head -10 |
  gum choose \
    --header="Choose a local commit to reset to:" \
    --label-delimiter="|" \
)

if [[ ! -z $HASH ]]; then
  echo "Discarding everything past hash $HASH!"

  read "REPLY?Do you wish to continue? [y/N] "
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    # Reset HEAD, the index, and all tracked files
    # to exactly match the specified commit
    git reset --hard "$HASH"

    # Remove all untracked files and directories
    # (files that did not exist at that commit)
    git clean -fd
  else
    echo "Submodule Reset skipped."
  fi
fi
