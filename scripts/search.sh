#!/bin/sh

search_db_by_keyword() {
    local keyword="$1"
    local exclusions="$2"
    echo "  Searching cache for '$keyword'"
    find "$ROOT_DIR/$ROM_DIR" -maxdepth 2 -type f -name "*cache7.db" | while IFS= read -r dbFile; do
        local fileName=$(basename "$dbFile")
        local tableName="${fileName%%_*}_roms"
        if sqlite3 "$dbFile" "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName';" | grep -q "$tableName"; then
            sqlite3 "$dbFile" "SELECT pinyin, path FROM $tableName WHERE path NOT LIKE '%.launch' AND pinyin COLLATE NOCASE LIKE '%$keyword%';" | while IFS='|' read -r displayName filePath; do
                create_shortcut "${filePath#*../../$ROM_DIR/}" "$(echo "$displayName" | sed 's/[\/:]/-/g')" "$exclusions"
            done
        fi
    done
}

search_db_by_keywords() {
    local keywords="$1"
    local exclusions="$2"
    echo "$keywords" | tr ',' '\n' | while IFS= read -r keyword; do
        keyword=$(echo "$keyword" | xargs)
        if [ -n "$keyword" ]; then
            search_db_by_keyword "$keyword" "$exclusions"
        fi
    done
}

search_files_by_keyword() {
    local keyword="$1"
    local exclusions="$2"
    echo "  Searching files for '$keyword'"
    find "$ROOT_DIR/$ROM_DIR" -type f -iname "*$keyword*" ! -iname "*.db" ! -path "*/.*/*" | while IFS= read -r foundFile; do
        local baseName=$(basename "$foundFile")
        create_shortcut "${foundFile#$ROOT_DIR/$ROM_DIR/}" "${baseName%.*}" "$exclusions"
    done
}

search_files_by_keywords() {
    local keywords="$1"
    local exclusions="$2"
    echo "$keywords" | tr ',' '\n' | while IFS= read -r keyword; do
        keyword=$(echo "$keyword" | xargs)
        if [ -n "$keyword" ]; then
            search_files_by_keyword "$keyword" "$exclusions"
        fi
    done
}

search_roms() {
    local searchTerms="$1"
    local excludeTerms="$2"

    addedFilesTemp=$(mktemp)
    echo ""
    echo "Identifying valid $collectionName collection items..."
    search_db_by_keywords "$searchTerms" "$excludeTerms"
    search_files_by_keywords "$searchTerms" "$excludeTerms"
    rm -f "$addedFilesTemp"
    sync
}