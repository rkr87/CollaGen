#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:$LD_LIBRARY_PATH"

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME=$(basename "$APP_DIR")

. "$APP_DIR/config.sh"
. "$APP_DIR/scripts/formats.sh"
. "$APP_DIR/scripts/utils.sh"
. "$APP_DIR/scripts/menus.sh"
. "$APP_DIR/scripts/collections.sh"
. "$APP_DIR/scripts/shortcuts.sh"
. "$APP_DIR/scripts/search.sh"
. "$APP_DIR/scripts/bulk.sh"

init() {
    local systemLanguage=$(get_json_value "$SYSTEM_FILE" $SYSTEM_LANGUAGE_KEY)    
    langFile="$LANG_DIR/$systemLanguage"
    if [ ! -d "$APP_DIR/config" ]; then
        mkdir -p "$APP_DIR/config"
    fi
    echo -e "\0033\0143"
    show_help
    show_main_menu
}

init