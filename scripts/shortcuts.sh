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

    local validEmuExt=$(get_json_value "$ROOT_DIR/$EMU_DIR/$subDir/$DEFAULT_CONFIG" "$EMU_EXT_KEY" "")

    local includeRom=1
    local excludeRom=0
    if grep -q "^$relativePath\$" "$addedFilesTemp"; then
        includeRom=0
    elif [[ $(has_valid_extension "$relativePath" "$validEmuExt") -eq 0 ]]; then
        includeRom=0
    elif grep -q "^$relativePath\$" "$excludedFilesTemp"; then
        includeRom=0
        excludeRom=1
    else
        oldIFS=$IFS
        IFS=','
        set -- $exclusions
        while [ "$#" -gt 0 ]; do
            exclusion=$(echo "$1" | xargs)
            local exclusionLower="$(lower_case "$exclusion")"
            if [[ "$shortcutNameLower" == *"$exclusionLower"* ]]; then
                includeRom=0
                excludeRom=1
                echo "$relativePath" >> "$excludedFilesTemp"
                echo_trim "$relativePath" 53 "    Excluding: " " ($exclusionLower)"
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
    elif [[ $excludeRom -eq 1 ]]; then
        if [ -f "$targetTextFile" ]; then
            rm "$targetTextFile"
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
    delete_cache
}

delete_cache() {
    cacheFile="$collectionDir/$ROM_DIR/$ROM_CACHE_FILE"
    if [ -f "$cacheFile" ]; then
        rm "$cacheFile"
    fi
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
            echo_trim "${file#*$ROM_DIR*}" 53 "  Broken shortcut: ~"
            echo_trim "${content#*$ROM_DIR*}" 53 "    Target: ~"
        fi
    done
}

delete_empty_folders() {
    find "$collectionDir" -type d -empty | while read -r dir; do
        rm -r "$dir"
        dirname=$(basename "$dir")
        echo_trim "$dirname" 53 "  Empty folder: "
    done
}

remove_redundant_images() {
    tmpFile=$(mktemp)
    find "$collectionDir/$ROM_DIR" -type f -name '*.txt' -exec basename {} .txt \; > "$tmpFile"
    find "$collectionDir/$IMG_DIR" -type f -name '*.png' | while IFS= read -r img; do
        imgName=$(basename "$img" .png)
        if ! grep -Fxq "$imgName" "$tmpFile"; then
            rm "$img"
            echo_trim "$$imgName" 53 "  Unlinked image: " ".png"
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