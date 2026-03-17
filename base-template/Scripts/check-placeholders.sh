#!/bin/sh
set -eu

placeholder_pattern='__[A-Z0-9_]+__'
matches=''

set -- \
  "$SRCROOT/project.yml" \
  "$SRCROOT/Config" \
  "$SRCROOT/App" \
  "$SRCROOT/Tests"

for path in "$@"; do
  if [ ! -e "$path" ]; then
    continue
  fi

  result=$(grep -RInE "$placeholder_pattern" "$path" || true)
  if [ -n "$result" ]; then
    matches="${matches}${result}
"
  fi
done

if [ -n "$matches" ]; then
  echo "error: unresolved template placeholders were found."
  printf "%s" "$matches"
  exit 1
fi

