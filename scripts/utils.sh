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
    local default_value="${3:-}"

    local value=$(sed -n "s/.*\"$key\":\s*\"\([^\"]*\)\".*/\1/p" "$file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [ -z "$value" ]; then
        value="$default_value"
    fi

    echo "$value"
}

set_json_value() {
    local file="$1"
    local key="$2"
    local new_value="$3"
    local escaped_value=$(printf '%s' "$new_value" | sed 's/[&/\]/\\&/g')
    sed -i "s/\"$key\":\s*\"[^\"]*\"/\"$key\": \"$escaped_value\"/" "$file"
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

echo_trim() {
    trimmable="$1"
    maxLen=$2
    prefix="$3"
    suffix="$4"

    preLen="${#prefix}"
    trimLen="${#trimmable}"
    sufLen="${#suffix}"

    strLen=$(($preLen + $trimLen + $sufLen))

    if [ $strLen -gt $maxLen ]; then
        relLen=$(($maxLen - $strLen + $trimLen - 3))
        trimmable="${trimmable:0:relLen}..."
    fi
    echo "$prefix$trimmable$suffix"
}

has_valid_extension() {
    local file_path="$1"
    local extensions="$2"
    local delimiter="${3:-|}"

    local file_extension="${file_path##*.}"

    if [ -z "$extensions" ]; then
        echo 1
        return 0
    fi

    local valid=0
    local ext
    while [ -n "$extensions" ]; do
        ext="${extensions%%"$delimiter"*}"
        [ "$extensions" = "$ext" ] && extensions="" || extensions="${extensions#*"$delimiter"}"

        if [ "$file_extension" = "$ext" ]; then
            valid=1
            break
        fi
    done

    echo $valid
}