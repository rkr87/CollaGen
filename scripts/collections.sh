#!/bin/sh

set_collection() {
    if [ "$#" -eq 0 ]; then
        collectionName=$(get_user_input "Enter a display name for the new collection:")
    else
        collectionName="$1"
    fi
    collectionDir="$ROOT_DIR/$BEST_DIR/$collectionName"
    local appCollDir="$APP_DIR/$CONFIG_DIR/$collectionName"
    mkdir -p "$appCollDir"
    touch "$appCollDir/$APP_INCLUDE"
    touch "$appCollDir/$APP_EXCLUDE"
    sync
}

create_collection() {
    set_collection
    if [ -d "$collectionDir" ]; then
        echo ""
        echo "Collection already exists, going to edit menu."
        show_edit_collection_menu "$collectionName"
    else
        mkdir -p "$collectionDir"
        if [ $? -eq 0 ]; then
            mkdir -p "$collectionDir/$IMG_DIR"
            mkdir -p "$collectionDir/$ROM_DIR"
            cp "$APP_DIR/$DEFAULTS_DIR/$DEFAULT_ICON" "$collectionDir/"
            cp "$APP_DIR/$DEFAULTS_DIR/$DEFAULT_BG" "$collectionDir/"
            cp "$APP_DIR/$DEFAULTS_DIR/$DEFAULT_LAUNCH" "$collectionDir/"
            create_collection_config
            echo ""
            echo "$collectionName collection created with default artwork."
            local collectionConfig="$APP_DIR/$CONFIG_DIR/$collectionName"
            delete_file_content "$collectionConfig/$APP_INCLUDE"; 
            delete_file_content "$collectionConfig/$APP_EXCLUDE"; 
            echo ""
            echo "Provide initial search terms (include)."
            edit_terms "$collectionConfig/$APP_INCLUDE" "" "search"
            sync
        fi
    fi
}

create_collection_config() {
    local configFile="$collectionDir/$DEFAULT_CONFIG"

    cat << EOF > "$configFile"
{
    "label": "$collectionName",
    "icon": "$DEFAULT_ICON",
    "background": "$DEFAULT_BG",
    "themecolor": "f0b402",
    "launch": "$DEFAULT_LAUNCH",
    "rompath": "./$ROM_DIR",
    "imgpath": "./$IMG_DIR",
    "useswap": 0,
    "shortname": 0,
    "hidebios": 1,
    "extlist": "txt"
}
EOF
}

delete_collection() {
    notified=0
    echo ""
    if [ -d "$collectionDir" ]; then
        rm -r "$collectionDir"
        echo "Deleted: $collectionName"
        notified=1
    fi

    appCollDir="$APP_DIR/$CONFIG_DIR/$collectionName"
    if [ -d "$appCollDir" ]; then
        rm -r "$appCollDir"
        if [ "$notified" -eq 0 ]; then
            echo "Deleted: $collectionName"
            notified=1
        fi 
    fi
    if [ "$notified" -eq 0 ]; then
        echo "$collectionName doesn't exist"
        notified=1
    fi 
}

edit_terms() {
    local file="$1"
    local currentTerms="$2"
    local triggerSearch="$3"
    local fileName=$(basename "$file")
    local termsType="${fileName%.*}"

    echo ""
    echo "Provide a comma separated list of terms. Each term is analysed independently, IE, entering 'mario,pokemon' will include or exclude all games that contain the word 'mario' OR 'pokemon'."
    if [ "$#" -eq 2 ]; then
        echo ""
        echo "Current terms: $currentTerms"
    fi
    local searchTerms=$(get_user_input "Enter terms:")
    save_list_to_file "$searchTerms" "$file"
    sync
    local newTerms=$(get_list_from_file "$file")
    if [ "$triggerSearch" == "search" ]; then
        search_roms "$newTerms" ""
        show_edit_collection_menu
    else
        show_edit_terms_menu "$file" "$newTerms"
    fi
}