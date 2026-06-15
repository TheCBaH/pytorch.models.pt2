#!/usr/bin/env bash
# Check that model JSON files in the working tree match git HEAD.
# On mismatch, pretty-prints both versions with jq and shows a unified diff
# so structural differences are visible even for minified single-line JSON.
set -euo pipefail

MODELS_DIR="${1:-models}"

changed=$(git diff --name-only HEAD -- "$MODELS_DIR")

if [ -z "$changed" ]; then
    echo "All model JSON files match HEAD."
    exit 0
fi

rc=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    echo "=== $file ==="
    if git show "HEAD:$file" >/dev/null 2>&1 && [ -f "$file" ]; then
        diff -u \
            --label "HEAD:$file" \
            --label "tree:$file" \
            <(git show "HEAD:$file" | jq .) \
            <(jq . "$file") || rc=1
    elif [ -f "$file" ]; then
        echo "(new file not in HEAD)"
        jq . "$file"
        rc=1
    else
        echo "(deleted from working tree)"
        git show "HEAD:$file" | jq .
        rc=1
    fi
done <<< "$changed"

if [ "$rc" -ne 0 ]; then
    echo ""
    echo "ERROR: model JSON files differ from HEAD. Run 'make extract' and commit."
fi
exit "$rc"
