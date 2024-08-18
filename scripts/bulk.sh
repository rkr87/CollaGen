#!/bin/sh

identify_valid_jobs() {
    validJobs=$(mktemp)
    request="$1"
    local configDir="$APP_DIR/$CONFIG_DIR"
    local osDir="$ROOT_DIR/$BEST_DIR"

    echo ""
    echo "Scanning collections..."
    echo ""

    local checkedCollections=""

    for appColl in "$configDir"/*; do
        if [ -d "$appColl" ]; then
            local appCollInclude="$appColl/$APP_INCLUDE"
            local appCollName=$(basename "$appColl")
            local osCollDir="$osDir/$appCollName"
            checkedCollections="$checkedCollections$appCollName\n"

            if [ "$request" == "delete" ]; then
                echo -e "$appCollName: ${GREEN}VALID${NO_FORMAT}"
                echo "$appCollName" >> "$validJobs"
                continue
            fi

            if [ ! -f "$appCollInclude" ]; then
                echo -e "$appCollName: ${RED}SEARCH TERM DEFINITIONS MISSING${NO_FORMAT}"
                continue
            fi

            if [ ! -s "$appCollInclude" ]; then
                echo -e "$appCollName: ${RED}NO SEARCH TERMS DEFINED${NO_FORMAT}"
                continue
            fi

            if [ ! -d "$osCollDir" ]; then
                echo -e "$appCollName: ${RED}COLLECTION DOESN'T EXIST${NO_FORMAT}"
                continue
            fi

            if [ ! -d "$osCollDir/$ROM_DIR" ] || [ ! -d "$osCollDir/$IMG_DIR" ] || [ ! -f "$osCollDir/$DEFAULT_CONFIG" ] || [ ! -f "$osCollDir/$DEFAULT_LAUNCH" ]; then
                echo -e "$appCollName: ${RED}COLLECTION MISSING REQUIRED FILES${NO_FORMAT}"
                continue
            fi

            echo -e "$appCollName: ${GREEN}VALID${NO_FORMAT}"
            echo "$appCollName" >> "$validJobs"
        fi
    done

    for osCollDir in "$osDir"/*; do
        if [ -d "$osCollDir" ]; then
            local osCollName=$(basename "$osCollDir")
            if echo -e "$checkedCollections" | grep -q -e "^$osCollName"; then
                continue
            fi
            echo -e "$osCollName: ${RED}NOT DEFINED IN COLLGEN${NO_FORMAT}"
            checkedCollections="$checkedCollections$appCollName\n"
        fi
    done
    local totalChecked=$(echo -e "$checkedCollections" | wc -l)
    local totalValid=$(wc -l < "$validJobs")
    totalChecked=$((totalChecked - 1))
    totalValid=$((totalValid))
    totalInvalid=$((totalChecked-totalValid))
    echo ""
    if [ "$totalChecked" -eq 0 ]; then
        echo -e "RESULTS: ${RED}No collections found${NO_FORMAT}"
    else
        echo -e "RESULTS: $totalChecked|${GREEN}$totalValid${NO_FORMAT}|${RED}$totalInvalid${NO_FORMAT}"
    fi
}

refresh_all_collections() {
    regen="$1"
    validJobs=$(mktemp)
    identify_valid_jobs

    echo ""
    local totalValid=$(wc -l < "$validJobs")

    if [ "$totalValid" -eq 0 ]; then
        echo "No valid collections found"
        show_main_menu
        return 0
    fi

    local validJobString=$(get_list_from_file "$validJobs")
    if [ "$regen" == "regen" ]; then
        echo "Regenerating a collection will remove any shortcuts you've manually added to a collection."
        echo "CollGen will only regenerate collections it has created or has been linked to, the below collections have been identified for regeneration."
        echo ""
        echo "$validJobString"
        local choice=$(get_user_input "Proceed y/[n]:" "n")
        case "$choice" in
            y) continue ;;
            *) show_main_menu; rm -f "$validJobs"; return 0 ;;
        esac
    fi

    while IFS= read -r job; do
        if [ -n "$job" ]; then
            set_collection "$job"
            if [ "$regen" == "regen" ]; then
                delete_collection_shortcuts
            fi
            execute_refresh "$job"
            if [ "$regen" != "regen" ]; then
                cleanup_collection
            fi
        fi
    done < "$validJobs"
    rm -f "$validJobs"
    show_main_menu
}

execute_refresh() {
    local job="$1"
    inc="$(get_list_from_file "$APP_DIR/$CONFIG_DIR/$collectionName/$APP_INCLUDE")"
    exc="$(get_list_from_file "$APP_DIR/$CONFIG_DIR/$collectionName/$APP_EXCLUDE")"
    search_roms "$inc" "$exc"
}

delete_all_collections() {
    validJobs=$(mktemp)
    identify_valid_jobs "delete"

    echo ""
    local totalValid=$(wc -l < "$validJobs")

    if [ "$totalValid" -eq 0 ]; then
        echo "No valid collections found"
        show_main_menu
        return 0
    fi

    local validJobString=$(get_list_from_file "$validJobs")
    echo "CollGen will only delete collections it has created or has been linked to, the below collections have been identified for deletion."
    echo ""
    echo "$validJobString"
    local choice=$(get_user_input "Proceed y/[n]:" "n")
    case "$choice" in
        y) execute_deletions "$validJobs" ;;
        *) show_main_menu ;;
    esac
}

execute_deletions() {
    local jobs_file="$1"

    while IFS= read -r job; do
        if [ -n "$job" ]; then
            set_collection "$job"
            delete_collection
        fi
    done < "$jobs_file"
    show_main_menu
    rm -f "$validJobs"
}