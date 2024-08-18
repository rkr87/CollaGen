#!/bin/sh

get_user_input() {
    local prompt="$1"
    local default="$2"
    while true; do
        echo "" >&2
        echo "$prompt" >&2
        read -r userInput

        if [ -n "$userInput" ]; then
            echo "$userInput" | xargs
            return
        elif [ -n "$default" ]; then
            echo "$default" | xargs
            return
        else
            echo ""
            echo "Input cannot be empty. Please try again." >&2
        fi
    done
}

save_list_to_file() {
    local words="$1"
    local filename="$2"
    echo "$words" | tr ',' '\n' | while read -r word; do
        trimmed_word=$(echo "$word" | xargs)
        if [ -n "$trimmed_word" ]; then
            echo "$trimmed_word" >> "$filename"
        fi
    done
}

get_list_from_file() {
    local filename="$1"
    local result=""
    while IFS= read -r line; do
        if [ -z "$result" ]; then
            result="$line"
        else
            result="$result,$line"
        fi
    done < "$filename"
    echo "$result"
}

delete_file_content() {
    local filename="$1"
    > "$filename"
}

get_json_value() {
    local file="$1"
    local key="$2"
    local value=$(sed -n "s/.*\"$key\":\s*\"\(.*\)\".*/\1/p" "$file")
    echo "$value"
}

set_json_value() {
    local file="$1"
    local key="$2"
    local new_value="$3"
    sed -i "s/\"$key\":\s*\"[^\"]*\"/\"$key\": \"$new_value\"/" "$file"
    sync
}

lower_case() {
    local string="$1"
    local stringLower=$(echo "$string" | tr '[:upper:]' '[:lower:]')
    echo "$stringLower"
}

list_to_string() {
    local commaList=$(echo "$1" | tr '\n' ',' | sed 's/,$//')
    echo "$commaList"
}