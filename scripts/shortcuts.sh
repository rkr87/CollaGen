#!/bin/sh

create_shortcut() {
    local relativePath="$1"
    local shortcutName="$2"
    local exclusions="$3"

    local subDir="${relativePath%%/*}"
    local fileName=$(basename "$relativePath")

    local shortcutNameLower=$(lower_case "$shortcutName")

    local targetDir="$collectionDir/$ROM_DIR/$subDir"
    local targetTextFile="$targetDir/$shortcutName.txt"
    local targetImgFile="$collectionDir/$IMG_DIR/$shortcutName.png"

    local includeRom=1
    if grep -q "^$relativePath\$" "$addedFilesTemp"; then
        local fileNameLower=$(lower_case "${fileName%.*}")
        if [[ "$fileNameLower" != "$shortcutNameLower" ]]; then
            includeRom=0
        fi
    else
        oldIFS=$IFS
        IFS=','
        set -- $exclusions
        while [ "$#" -gt 0 ]; do
            exclusion=$(echo "$1" | xargs)
            local exclusionLower="$(lower_case "$exclusion")"

            if [[ "$shortcutNameLower" == *"$exclusionLower"* ]]; then
                includeRom=0
                echo "    Excluding: $relativePath ($exclusionLower)"
                break
            fi
            shift
        done
        IFS=$oldIFS
    fi

    if [[ $includeRom -eq 1 ]]; then
        mkdir -p "$targetDir"
        echo "$ROOT_DIR/$ROM_DIR/$relativePath" > "$targetTextFile"
        echo "$relativePath" >> "$addedFilesTemp"
        local imgFile="$ROOT_DIR/$IMG_DIR/${relativePath%.*}.png"
        if [ -f "$imgFile" ] && [ ! -f "$targetImgFile" ]; then
            cp "$imgFile" "$targetImgFile"
        fi
    else
        if [ -f "$targetTextFile" ]; then
            rm "$targetTextFile"
            echo "    Removed: $subDir/$shortcutName.txt"
        fi
        if [ -f "$targetImgFile" ]; then
            rm "$targetImgFile"
        fi
    fi
}

cleanup_collection() {
    echo "Cleaning up $collectionName collection..."
    remove_broken_shortcuts
    delete_empty_folders
    remove_redundant_images
}

remove_broken_shortcuts() {
    find "$collectionDir" -type f -name '*.txt' | while read -r file; do
        content=$(head -n 1 "$file")
        if [ ! -f "$content" ]; then
            rm "$file"
            local fileName=$(basename "$file")
            local imgFile="$collectionDir/$IMG_DIR/${fileName%.*}.png"
            if [ -f "$imgFile" ]; then
                rm "$imgFile"
            fi
            echo "  Removed broken shortcut: ~${file#*$ROM_DIR*}"
            echo "    Target: ~${content#*$ROM_DIR*}"
        fi
    done
}

delete_empty_folders() {
    find "$collectionDir" -type d -empty | while read -r dir; do
        rm -r "$dir"
        dirname=$(basename "$dir")
        echo "  Removed empty folder: $dirname"
    done
}

remove_redundant_images() {
    tmpFile=$(mktemp)
    find "$collectionDir/$ROM_DIR" -type f -name '*.txt' -exec basename {} .txt \; > "$tmpFile"
    find "$collectionDir/$IMG_DIR" -type f -name '*.png' | while IFS= read -r img; do
        imgName=$(basename "$img" .png)
        if ! grep -Fxq "$imgName" "$tmpFile"; then
            rm "$img"
            echo "  Remove image: $imgName.png"
        fi
    done
    rm "$tmpFile"
}

delete_collection_shortcuts() {
    if [ -d "$collectionDir/$ROM_DIR" ]; then
        rm -rf "$collectionDir/$ROM_DIR/"*
    fi
    if [ -d "$collectionDir/$IMG_DIR" ]; then
        rm -rf "$collectionDir/$IMG_DIR/"*
    fi
}