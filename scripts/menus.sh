#!/bin/sh

show_help() {
    if [ "$#" -ne 0 ]; then
        echo ""
    fi
    echo "$APP_NAME v$VERSION"
    echo ""
    echo "Y: Toggle keyboard"
    echo "X: Reposition keyboard"
    echo "B: BACKSPACE"
    echo "HOLD-L1: SHIFT"
    echo "R1: Lock key (Lock SHIFT for CAPS LOCK)"
    echo "START: Enter/Submit"
    echo "MENU: Exit app (with keyboard visible)"
}

show_main_menu() {
    local bestTabName=$(get_json_value "$langFile" "$LANG_BEST_TAB_KEY")
    echo ""
    echo "Select an option:"
    echo "  1: Create collection"
    echo "  2: Edit/Delete collection"
    echo "  3: Refresh all collections (append)"
    echo "  4: Regenerate all collections (reset and rebuild)"
    echo "  5: Delete all collections"
    echo "  6: Rename '$bestTabName' tab"
    echo ""
    echo "  0: Show help"
    local choice=$(get_user_input "Enter your choice:")
    case "$choice" in
        1) create_collection ;;
        2) show_collections_menu ;;
        3) refresh_all_collections ;; 
        4) refresh_all_collections "regen" ;;
        5) delete_all_collections ;;
        6) show_rename_best_tab_menu "$bestTabName" ;;
        0) show_help -nl; show_main_menu ;;
        *) echo "Invalid selection, please try again."; show_main_menu ;;
    esac
}

show_collections_menu() {
    local directory="$ROOT_DIR/$BEST_DIR"

    echo ""
    echo "Select a collection:"
    local i=1
    local selected=""
    
    for dir in "$directory"/*/; do
        if [ -d "$dir" ]; then
            echo "  $i: $(basename "$dir")"
            eval "dir_$i=\"$(basename "$dir")\""
            i=$((i+1))
        fi
    done

    if [ "$i" -eq 1 ]; then
        echo "No existing collections found."
        show_main_menu
    fi

    echo ""
    echo "  0: Return to main menu"

    local choice=$(get_user_input "Enter your choice:")
    if [ "$choice" -ge 0 ] && [ "$choice" -lt "$i" ]; then
        if [ "$choice" -eq 0 ]; then
            show_main_menu
        else
            eval "selected=\$dir_$choice"
            set_collection "$selected"
            show_edit_collection_menu
        fi
    else
        echo "Invalid selection, please try again."
        show_collections_menu
    fi
}

show_edit_collection_menu() {

    local includeFile="$APP_DIR/$CONFIG_DIR/$collectionName/$APP_INCLUDE"
    local excludeFile="$APP_DIR/$CONFIG_DIR/$collectionName/$APP_EXCLUDE"
    local existingTerms=""
    local existingExclusions=""

    echo ""
    echo "Editing collection: $collectionName"

    if [ -f "$includeFile" ]; then
        existingTerms="$(get_list_from_file "$includeFile")"
        echo "Existing search terms: $existingTerms"
    fi

    if [ -f "$excludeFile" ]; then
        existingExclusions="$(get_list_from_file "$excludeFile")"
        echo "Existing exclusion terms: $existingExclusions"
    fi

    echo ""
    echo "Select an option:"
    echo "  1: Edit inclusion terms"
    echo "  2: Edit exclusion terms"
    echo "  3: Refresh collection (append)"
    echo "  4: Regenerate collection (reset and rebuild)"
    echo "  5: Delete collection"
    echo ""
    echo "  9: Return to collections menu"
    echo "  0: Return to main menu"
    local choice=$(get_user_input "Enter your choice:")    
    case "$choice" in
        1) show_edit_terms_menu "$includeFile" "$existingTerms" ;;
        2) show_edit_terms_menu "$excludeFile" "$existingExclusions" ;;
        3) search_roms "$existingTerms" "$existingExclusions"; cleanup_collection; show_edit_collection_menu ;;
        4) delete_collection_shortcuts; search_roms "$existingTerms" "$existingExclusions"; show_edit_collection_menu ;;
        5) delete_collection; show_main_menu ;;
        9) show_collections_menu ;;
        0) show_main_menu ;;
        *) echo "Invalid selection, please try again."; show_edit_collection_menu ;;
    esac
}

show_edit_terms_menu() {
    local file="$1"
    local currentTerms="$2"
    local fileName=$(basename "$1")
    local termsType="${fileName%.*}"

    echo ""
    echo "Editing collection: $collectionName"
    echo "Existing $termsType terms: $currentTerms"

    echo ""
    echo "Select an option:"
    echo "  1: Reset term(s)"
    echo "  2: Add term(s)"
    echo "  3: Remove term(s)"
    echo ""
    echo "  8: Return to $collectionName collection menu"
    echo "  9: Return to collections menu"
    echo "  0: Return to main menu"
    local choice=$(get_user_input "Enter your choice:")    
    case "$choice" in
        1) delete_file_content "$file"; edit_terms "$file" ;;
        2) edit_terms "$file" "$currentTerms" ;;
        3) show_remove_terms_menu "$file" ;;
        8) show_edit_collection_menu ;;
        9) show_collections_menu ;;
        0) show_main_menu ;;
        *) echo "Invalid selection, please try again."; show_edit_terms_menu "$file" "$currentTerms" ;;
    esac
}


show_remove_terms_menu() {
    local file="$1"

    if [ ! -s "$file" ]; then
        echo "No existing terms found."
        show_edit_terms_menu "$file" ""
        return 1
    fi

    echo ""
    echo "Select a term to delete:"
    nl -w2 -s': ' "$file" | sed 's/^/ /'
    echo ""
    echo "  0: Cancel"

    local term_count=$(wc -l < "$file")

    local choice=$(get_user_input "Enter your choice:")
    if [ "$choice" -ge 0 ] 2>/dev/null && [ "$choice" -le "$term_count" ]; then
        if [ "$choice" -eq 0 ]; then
            local readTerms=$(get_list_from_file "$file")
            show_edit_terms_menu "$file" "$readTerms"
        else
            sed -i "${choice}d" "$file"
            show_remove_terms_menu "$file"
        fi
    else
        echo "Invalid selection, please try again."
        show_remove_terms_menu "$file"
    fi
}

show_rename_best_tab_menu() {
    local currentName="$1"
    echo ""
    echo "Current Tab Name: $currentName"
    echo ""
    echo "Select an option:"
    echo "  1: Rename to 'Collections'"
    echo "  2: Rename to 'Best'"
    echo "  3: Enter custom name"
    echo ""
    echo "  0: Return to main menu"
    local choice=$(get_user_input "Enter your choice:")    
    case "$choice" in
        1) set_json_value "$langFile" "$LANG_BEST_TAB_KEY" "Collections" ;;
        2) set_json_value "$langFile" "$LANG_BEST_TAB_KEY" "Best" ;;
        3) local newName=$(get_user_input "Enter a custom name:"); set_json_value "$langFile" "$LANG_BEST_TAB_KEY" "$newName" ;;
        0) show_main_menu ;;
        *) echo "Invalid selection, please try again."; show_rename_best_tab_menu "$currentName" ;;
    esac
    show_main_menu
}