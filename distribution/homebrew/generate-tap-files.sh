#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage:
  generate-tap-files.sh --version <x.y.z> --tap-dir <path> [options]

Required:
  --version <x.y.z>          Release version. The Git tag defaults to v<version>.
  --tap-dir <path>           Local checkout path for the homebrew tap repository.

Source repository:
  --owner <name>             GitHub owner or org.
  --source-repo <name>       Source repository name.
  --source-url <git-url>     Override the source Git URL. Useful for private SSH URLs.
  --tag <tag>                Override the Git tag. Defaults to v<version>.
  --revision <sha>           Override the Git commit SHA. Defaults to git ls-remote lookup.

Tap metadata:
  --tap-name <name>          Tap repository name. Default: homebrew-base
  --tap-url <git-url>        Tap clone URL used in the generated README.
  --formula-name <name>      Formula/binary name. Default: base
  --homepage <url>           Homepage shown in the formula.
  --desc <text>              Formula description.
  --license <value>          SPDX license string or a Ruby symbol like :cannot_represent.

Examples:
  ./distribution/homebrew/generate-tap-files.sh \
    --owner your-org \
    --source-repo base-project \
    --version 0.1.0 \
    --tap-dir ~/src/homebrew-base

  ./distribution/homebrew/generate-tap-files.sh \
    --source-url git@github.com:your-org/base-project.git \
    --owner your-org \
    --source-repo base-project \
    --version 0.1.0 \
    --tap-dir ~/src/homebrew-base
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_value() {
  option="$1"
  value="${2-}"
  [ -n "${value}" ] || die "Missing value for ${option}"
}

normalize_version() {
  printf '%s' "$1" | sed 's/^v//'
}

formula_class_name() {
  printf '%s' "$1" | awk -F'[-_]' '{
    result = ""
    for (i = 1; i <= NF; i++) {
      part = $i
      if (part == "") {
        continue
      }
      first = toupper(substr(part, 1, 1))
      rest = substr(part, 2)
      result = result first rest
    }
    print result
  }'
}

resolve_revision() {
  repo_url="$1"
  git_tag="$2"

  annotated=$(git ls-remote "$repo_url" "refs/tags/$git_tag^{}" | awk 'NR==1 { print $1 }')
  if [ -n "$annotated" ]; then
    printf '%s\n' "$annotated"
    return 0
  fi

  direct=$(git ls-remote "$repo_url" "refs/tags/$git_tag" | awk 'NR==1 { print $1 }')
  if [ -n "$direct" ]; then
    printf '%s\n' "$direct"
    return 0
  fi

  die "Could not resolve revision for tag ${git_tag} from ${repo_url}"
}

license_literal() {
  case "$1" in
    :*)
      printf '%s\n' "$1"
      ;;
    *)
      printf '"%s"\n' "$1"
      ;;
  esac
}

owner=""
source_repo=""
source_url=""
version=""
tag=""
revision=""
tap_dir=""
tap_name="homebrew-base"
tap_url=""
formula_name="base"
homepage=""
description="Internal SwiftUI app scaffolder"
license_value=":cannot_represent"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --owner)
      require_value "$1" "${2-}"
      owner="$2"
      shift 2
      ;;
    --source-repo)
      require_value "$1" "${2-}"
      source_repo="$2"
      shift 2
      ;;
    --source-url)
      require_value "$1" "${2-}"
      source_url="$2"
      shift 2
      ;;
    --version)
      require_value "$1" "${2-}"
      version=$(normalize_version "$2")
      shift 2
      ;;
    --tag)
      require_value "$1" "${2-}"
      tag="$2"
      shift 2
      ;;
    --revision)
      require_value "$1" "${2-}"
      revision="$2"
      shift 2
      ;;
    --tap-dir)
      require_value "$1" "${2-}"
      tap_dir="$2"
      shift 2
      ;;
    --tap-name)
      require_value "$1" "${2-}"
      tap_name="$2"
      shift 2
      ;;
    --tap-url)
      require_value "$1" "${2-}"
      tap_url="$2"
      shift 2
      ;;
    --formula-name)
      require_value "$1" "${2-}"
      formula_name="$2"
      shift 2
      ;;
    --homepage)
      require_value "$1" "${2-}"
      homepage="$2"
      shift 2
      ;;
    --desc)
      require_value "$1" "${2-}"
      description="$2"
      shift 2
      ;;
    --license)
      require_value "$1" "${2-}"
      license_value="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[ -n "$version" ] || die "--version is required"
[ -n "$tap_dir" ] || die "--tap-dir is required"

if [ -z "$source_url" ]; then
  [ -n "$owner" ] || die "--owner is required when --source-url is not passed"
  [ -n "$source_repo" ] || die "--source-repo is required when --source-url is not passed"
  source_url="https://github.com/${owner}/${source_repo}.git"
fi

if [ -z "$homepage" ]; then
  if [ -n "$owner" ] && [ -n "$source_repo" ]; then
    homepage="https://github.com/${owner}/${source_repo}"
  else
    homepage="https://example.invalid/base-project"
  fi
fi

if [ -z "$tap_url" ]; then
  if [ -n "$owner" ]; then
    tap_url="https://github.com/${owner}/${tap_name}"
  else
    tap_url="https://example.invalid/${tap_name}"
  fi
fi

if [ -z "$tag" ]; then
  tag="v${version}"
fi

if [ -z "$revision" ]; then
  revision=$(resolve_revision "$source_url" "$tag")
fi

formula_class=$(formula_class_name "$formula_name")
license_ruby=$(license_literal "$license_value")
formula_dir="${tap_dir%/}/Formula"
formula_path="${formula_dir}/${formula_name}.rb"
tap_readme_path="${tap_dir%/}/README.md"

mkdir -p "$formula_dir"

cat > "$formula_path" <<EOF
class ${formula_class} < Formula
  desc "${description}"
  homepage "${homepage}"
  url "${source_url}",
      tag:      "${tag}",
      revision: "${revision}"
  version "${version}"
  license ${license_ruby}

  depends_on "xcodegen"
  depends_on "cocoapods"

  def install
    system "swift", "build", "--disable-sandbox", "--configuration", "release", "--product", "${formula_name}", "--package-path", "base-cli"
    bin.install "base-cli/.build/release/${formula_name}"

    template_root = share/"base-cli/template"
    template_root.mkpath
    FileUtils.cp_r(
      Dir["base-template/{*,.*}"].reject { |path| [".", ".."].include?(File.basename(path)) },
      template_root
    )
  end

  def caveats
    <<~EOS
      Optional:
        brew install swiftlint
    EOS
  end

  test do
    output_path = testpath/"SmokeApp"
    system bin/"${formula_name}", "new",
      "--app-name", "Smoke App",
      "--target-name", "SmokeApp",
      "--bundle-id", "com.example.smokeapp",
      "--with-cocoapods",
      "--output", output_path,
      "--skip-generate",
      "--skip-pod-install",
      "--no-input"

    assert_path_exists output_path/"project.yml"
    assert_path_exists output_path/"Podfile"
    assert_match "name: SmokeApp", (output_path/"project.yml").read
  end
end
EOF

cat > "$tap_readme_path" <<EOF
# ${tap_name}

Homebrew tap for the internal \`${formula_name}\` scaffolding CLI.

## Install

If this tap is public or readable through standard GitHub access:

\`\`\`bash
brew install ${owner:-your-org}/${tap_name}/${formula_name}
\`\`\`

If this tap is private, do a one-time tap with the Git URL, then install:

\`\`\`bash
brew tap ${owner:-your-org}/${tap_name} ${tap_url}
brew install ${formula_name}
\`\`\`

## Upgrade

\`\`\`bash
brew update
brew upgrade ${formula_name}
\`\`\`

## First use

\`\`\`bash
${formula_name} new
\`\`\`
EOF

echo "Wrote formula to ${formula_path}"
echo "Wrote tap README to ${tap_readme_path}"
echo "Resolved source revision: ${revision}"
