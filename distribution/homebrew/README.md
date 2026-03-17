# Homebrew Distribution

This directory contains the maintainer tooling for distributing `base` to the team with Homebrew.

## Recommended internal setup

For an internal team, the most practical setup is:

1. Keep this monorepo as the source repo.
2. Create a separate tap repo named `homebrew-base`.
3. Point the formula at the source repo using a Git `tag` + `revision`.

Why this setup:

- It works with private repositories more reliably than a public tarball + `sha256` flow.
- It avoids hand-editing `Formula/base.rb` on every release.
- The installed CLI can bundle `base-template/` into `share/base-cli/template`, which matches the runtime lookup in `base-cli`.

## Maintainer flow

1. Tag the source repo, for example `v0.1.0`.
2. Clone or update the tap repo locally.
3. Generate the formula:

```bash
./distribution/homebrew/generate-tap-files.sh \
  --owner your-org \
  --source-repo base-project \
  --version 0.1.0 \
  --tap-dir ~/src/homebrew-base
```

By default the script now checks remote tags in this order:

- `v<version>`
- `<version>`

So `--version 0.1.1` works whether your Git tag is `v0.1.1` or `0.1.1`. If you want to pin an exact tag name, pass `--tag`.

If the source repo is private and your team uses SSH for GitHub, pass an explicit source URL:

```bash
./distribution/homebrew/generate-tap-files.sh \
  --owner your-org \
  --source-repo base-project \
  --source-url git@github.com:your-org/base-project.git \
  --version 0.1.0 \
  --tap-dir ~/src/homebrew-base \
  --tap-url git@github.com:your-org/homebrew-base.git
```

The script accepts scp-style Git SSH URLs like `git@github.com:your-org/base-project.git` and rewrites them to `ssh://git@github.com/your-org/base-project.git` inside the generated formula, because Homebrew requires a URI-style Git URL there.

4. Commit and push the updated tap repo.

## User flow

Public or standard GitHub-readable tap:

```bash
brew install your-org/homebrew-base/base
base new
```

Private tap:

```bash
brew tap your-org/homebrew-base git@github.com:your-org/homebrew-base.git
brew install base
base new
```

## Notes

- The formula installs `xcodegen` as a dependency because `base new` generates the Xcode project after copying the template.
- `swiftlint` stays optional. The generated template already skips the lint build phase if SwiftLint is not installed.
- The formula test only runs `base new --skip-generate`; that keeps the Homebrew test fast while still proving that template copy and token replacement work.
