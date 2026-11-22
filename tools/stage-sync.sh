#!/bin/sh
# Copies the files changed in the last N commits (default 1) to a new
# /mnt/user-data/outputs/sync-<timestamp>/ folder and prints the JSON "files" list
# for device_commit_files (both AddOns folders). Only files the game loads
# (.toc, .lua, Media) are included (no .md).
#
# Usage (from the repo root):  sh tools/stage-sync.sh [N]
set -e
N=${1:-1}
D=/mnt/user-data/outputs/sync-$(date +%Y%m%d-%H%M%S)
mkdir -p "$D"
FILES=$(git diff --name-only --diff-filter=AM "HEAD~$N" HEAD | grep -E '\.(toc|lua|ttf|tga|blp)$' | grep -v '^docs/\|^tools/\|^Branding/' || true)
[ -z "$FILES" ] && { echo "[]"; exit 0; }
SEP=""
printf '['
for f in $FILES; do
    mkdir -p "$D/$(dirname "$f")"
    cp "$f" "$D/$f"
    w=$(printf '%s' "$f" | sed 's#/#\\\\#g')
    for c in _retail_ _forever_; do
        printf '%s{"stagedPath":"%s/%s","devicePath":"G:\\\\World of Warcraft\\\\%s\\\\Interface\\\\AddOns\\\\NitexUI\\\\%s"}' "$SEP" "$D" "$f" "$c" "$w"
        SEP=","
    done
done
printf ']\n'
for f in $FILES; do printf '%s %s\n' "$(wc -c < "$f")" "$f" >&2; done
