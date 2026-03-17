#!/bin/sh
set -eu

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "warning: SwiftLint is not installed. Skipping lint build phase."
  exit 0
fi

swiftlint --config "$SRCROOT/.swiftlint.yml"

