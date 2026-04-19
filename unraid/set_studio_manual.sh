#!/bin/bash

# set_studio_manual.sh
# Usage: ./set_studio_manual.sh "/path/to/folder" "StudioName"

TARGET_FOLDER="$1"
STUDIO="$2"

if [ -z "$TARGET_FOLDER" ] || [ -z "$STUDIO" ]; then
    echo "Usage: $0 \"/path/to/folder\" \"StudioName\""
    echo "Example: $0 \"/mnt/user/data/movies/Cool Studio\" \"Cool Studio\""
    exit 1
fi

if [ ! -d "$TARGET_FOLDER" ]; then
    echo "Error: Folder '$TARGET_FOLDER' not found"
    exit 1
fi

cd "$TARGET_FOLDER" || exit 1

echo "Processing .nfo files in: $TARGET_FOLDER"
echo "Using studio name: $STUDIO"
echo ""

SKIPPED=0
MODIFIED=0

find . -name "*.nfo" -exec bash -c '
    NFO_FILE="$1"
    STUDIO="$2"
    CHANGED=0
    
    # Check if <studio> already exists; if not, add it. Then add <set>.
    if ! grep -q "<studio>" "$NFO_FILE"; then
        sed -i "/<\/title>/a \  <studio>$STUDIO</studio>" "$NFO_FILE"
        CHANGED=1
    fi
    
    # Add the <set> tag (Collection) right after the studio tag
    if ! grep -q "<set>" "$NFO_FILE"; then
        sed -i "/<\/studio>/a \  <set>$STUDIO</set>" "$NFO_FILE"
        CHANGED=1
    fi
    
    if [ $CHANGED -eq 1 ]; then
        echo "[$(date +%H:%M:%S)] Updated: $NFO_FILE"
        ((MODIFIED++))
    else
        ((SKIPPED++))
    fi
' -- {} "$STUDIO" \;

echo ""
echo "=== Summary ==="
echo "Modified: $MODIFIED"
echo "Already had tags (skipped): $SKIPPED"
