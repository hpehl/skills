#!/usr/bin/env bash
# Requires bash 4.0+ for arrays and extended globbing
set -euo pipefail

# filter-unmanaged.sh — Filter chezmoi unmanaged files against exclusion patterns
#
# Usage: filter-unmanaged.sh <excludes.yaml> [<excludes.local.yaml>]
# Outputs: One unmanaged file path per line (relative to home directory)

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <excludes.yaml> [<excludes.local.yaml>]" >&2
    exit 1
fi

EXCLUDES_FILE="$1"
EXCLUDES_LOCAL_FILE="${2:-}"

if ! command -v chezmoi &>/dev/null; then
    echo "Error: chezmoi not found in PATH" >&2
    exit 1
fi

if [[ ! -f "$EXCLUDES_FILE" ]]; then
    echo "Error: excludes file not found: $EXCLUDES_FILE" >&2
    exit 1
fi

# Parse patterns from a YAML file
# Uses yq if available, falls back to grep+sed
parse_patterns() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi

    if command -v yq &>/dev/null; then
        yq -r '.patterns[]? // empty' "$file" 2>/dev/null
    else
        # Fallback: handles simple "- pattern" lists only (no flow syntax or multi-line strings)
        # Remove leading spaces, dash, quotes, and trailing comments
        grep -E '^[ \t]*-[ \t]+' "$file" | \
            sed 's/^[ \t]*-[ \t]*//' | \
            sed 's/^"//' | \
            sed 's/"$//' | \
            sed "s/^'//" | \
            sed "s/'$//" | \
            sed 's/#.*//' | \
            sed 's/[ \t]*$//'
    fi
}

# Collect all exclusion patterns
patterns=()
while IFS= read -r pattern; do
    [[ -n "$pattern" ]] && patterns+=("$pattern")
done < <(parse_patterns "$EXCLUDES_FILE")

if [[ -n "$EXCLUDES_LOCAL_FILE" ]]; then
    while IFS= read -r pattern; do
        [[ -n "$pattern" ]] && patterns+=("$pattern")
    done < <(parse_patterns "$EXCLUDES_LOCAL_FILE")
fi

# Check if a path matches any exclusion pattern
matches_exclusion() {
    local path="$1"
    local result=1
    shopt -s extglob nullglob

    for pattern in "${patterns[@]}"; do
        # Direct match: ".DS_Store", ".cache", "Library/*"
        if [[ "$path" == $pattern ]]; then
            result=0; break
        fi

        # Directory match: ".cache/*" matches ".cache" and ".cache/foo"
        if [[ "$pattern" == */ || "$pattern" == */* ]]; then
            local dir_pattern="${pattern%/\*}"
            if [[ "$path" == "$dir_pattern" || "$path" == "$dir_pattern"/* ]]; then
                result=0; break
            fi
        fi

        # Depth-independent match: "*/Cache/*" matches "foo/Cache/bar"
        if [[ "$pattern" == \*/* ]]; then
            local suffix="${pattern#\*/}"
            suffix="${suffix%/\*}"
            if [[ "$path" == */"$suffix" || "$path" == */"$suffix"/* ]]; then
                result=0; break
            fi
        fi
    done

    shopt -u extglob nullglob
    return $result
}

# Get unmanaged entries from chezmoi, filter to files, apply exclusions
chezmoi unmanaged --path-style=relative 2>/dev/null | while IFS= read -r entry; do
    # Resolve full path to check if it's a file (not directory)
    full_path="$HOME/$entry"
    if [[ ! -f "$full_path" ]]; then
        continue
    fi

    # Check against exclusion patterns
    if ! matches_exclusion "$entry"; then
        echo "$entry"
    fi
done
