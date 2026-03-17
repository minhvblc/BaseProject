# Base Project

This workspace now contains both parts of the starter setup:

- `base-template/` contains the SwiftUI XcodeGen template.
- `base-cli/` contains the Swift Package executable that scaffolds new apps from that template.

## Template

The template lives in `base-template/` and includes:

- SwiftUI starter app structure
- `project.yml` for XcodeGen
- layered `xcconfig` files
- build phase scripts
- a unit-test target

## CLI

The CLI package lives in `base-cli/`.

### Local usage

```bash
cd base-cli
swift run base new --app-name "Wallet Demo" --bundle-id "com.example.walletdemo"
```

Useful options:

- `--with-cocoapods`
- `--skip-pod-install`
- `--target-name`
- `--output`
- `--template`
- `--skip-generate`
- `--force`
- `--no-input`

### Current template discovery order

1. `--template <path>`
2. `BASE_TEMPLATE_PATH`
3. Homebrew-style `share/base-cli/template`
4. a sibling `base-template/` directory in the workspace

## Internal distribution

Homebrew packaging assets for the internal team live in `distribution/homebrew/`.

Recommended maintainer flow:

```bash
./distribution/homebrew/generate-tap-files.sh \
  --owner your-org \
  --source-repo base-project \
  --version 0.1.0 \
  --tap-dir ~/src/homebrew-base
```

Recommended user flow:

```bash
brew install your-org/homebrew-base/base
base new
```

If the app should start with CocoaPods:

```bash
base new --with-cocoapods
```

## Testing the generator

Quick smoke test without CocoaPods:

```bash
./scripts/test-generation.sh
```

Smoke test with CocoaPods enabled:

```bash
./scripts/test-generation.sh --with-cocoapods
```

What this does:

- runs `swift test` in `base-cli`
- scaffolds a real sample app via `base new`
- builds the generated `.xcodeproj` or `.xcworkspace` with `xcodebuild`
