# __TARGET_NAME__ Template

Internal SwiftUI starter template backed by XcodeGen.

## What is included

- SwiftUI app skeleton using modern APIs.
- XcodeGen project spec at `project.yml`.
- Layered build settings in `Config/Base.xcconfig`, `Config/Debug.xcconfig`, and `Config/Release.xcconfig`.
- Build phase scripts in `Scripts/` for placeholder validation and optional SwiftLint.
- Optional CocoaPods integration when scaffolded through `base-cli`.
- Unit test target using Swift Testing.
- `TemplateManifest.json` for the future scaffold CLI.

## Template tokens

Replace these tokens before generating the project:

- `__APP_DISPLAY_NAME__`
- `__TARGET_NAME__`
- `__BUNDLE_ID__`

## Local usage before the CLI exists

1. Replace the template tokens.
2. Install XcodeGen with `brew install xcodegen`.
3. Run `Scripts/generate.sh`.
4. Open `__TARGET_NAME__.xcodeproj`.

## Suggested repo flow

- Keep this repo as `base-template`.
- Build a separate `base-cli` that copies this template, replaces tokens, and runs XcodeGen.

## CocoaPods

When creating a project through `base-cli`, you can enable CocoaPods so the scaffold also emits a `Podfile` and can run `pod install`.

If CocoaPods is enabled and installation runs successfully, open `__TARGET_NAME__.xcworkspace` instead of the Xcode project file.
