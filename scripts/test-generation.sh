#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/test-generation.sh [--with-cocoapods] [--skip-unit-tests] [--keep-output]

Options:
  --with-cocoapods   Generate a Podfile, run `pod install`, and build the workspace.
  --skip-unit-tests  Skip `swift test` in base-cli.
  --keep-output      Keep the generated temporary project directory.
  -h, --help         Show this help text.
EOF
}

with_cocoapods=false
skip_unit_tests=false
keep_output=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-cocoapods)
      with_cocoapods=true
      ;;
    --skip-unit-tests)
      skip_unit_tests=true
      ;;
    --keep-output)
      keep_output=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cli_root="$repo_root/base-cli"

app_name="Smoke Test App"
target_name="SmokeTestApp"
bundle_id="com.example.smoketestapp"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/base-smoke-test.XXXXXX")"
project_root="$output_root/$target_name"

cleanup() {
  if [[ "$keep_output" == true ]]; then
    echo "Generated project kept at: $project_root"
  else
    rm -rf "$output_root"
  fi
}
trap cleanup EXIT

echo "Repo root: $repo_root"

if [[ "$skip_unit_tests" == false ]]; then
  echo
  echo "1/3 Running CLI unit tests"
  (
    cd "$cli_root"
    swift test
  )
fi

echo
echo "2/3 Generating a sample project"
cmd=(
  swift run base new
  --app-name "$app_name"
  --target-name "$target_name"
  --bundle-id "$bundle_id"
  --output "$project_root"
  --force
  --no-input
)

if [[ "$with_cocoapods" == true ]]; then
  cmd+=(--with-cocoapods)
fi

(
  cd "$cli_root"
  "${cmd[@]}"
)

echo
echo "3/3 Building the generated project"
if [[ "$with_cocoapods" == true ]]; then
  xcodebuild \
    -workspace "$project_root/$target_name.xcworkspace" \
    -scheme "$target_name" \
    -destination "generic/platform=iOS Simulator" \
    build-for-testing
else
  xcodebuild \
    -project "$project_root/$target_name.xcodeproj" \
    -scheme "$target_name" \
    -destination "generic/platform=iOS Simulator" \
    build-for-testing
fi

echo
echo "Smoke test passed."
if [[ "$with_cocoapods" == true ]]; then
  echo "Verified scaffold + xcodegen + pod install + workspace build."
else
  echo "Verified scaffold + xcodegen + project build."
fi
