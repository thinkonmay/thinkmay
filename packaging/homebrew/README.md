# Thinkmay Client — Homebrew

Install the Thinkmay desktop client with [Homebrew](https://brew.sh) on **macOS** and **Linux**.

## Tap (recommended)

This repository is a Homebrew tap. After the first GitHub release is published:

```bash
brew tap thinkonmay/thinkmay https://github.com/thinkonmay/thinkmay.git
```

If you maintain a dedicated tap repository (`github.com/thinkonmay/homebrew-tap`), point customers there instead:

```bash
brew tap thinkonmay/tap
```

## Install

**macOS** (`.app` bundle):

```bash
brew install --cask thinkmay-client
```

**Linux** (prebuilt binary + bundled libraries):

```bash
brew install thinkmay-client
```

Then run:

```bash
thinkmay-client --help
thinkmay-client "thinkmay:https://thinkmay.net/en/remote/?vmid=..."
```

## Upgrade

```bash
brew update
brew upgrade --cask thinkmay-client   # macOS
brew upgrade thinkmay-client          # Linux
```

## Local development (from a git checkout)

Build client packages with CI or locally, refresh checksums, then install via a **local tap** (Homebrew rejects bare `.rb` paths):

```bash
# After client-package artifacts exist under ./artifacts/
./packaging/homebrew/update-formulae.sh ./artifacts

# macOS or Linux (Homebrew on Linux)
./packaging/homebrew/test-install.sh macos ./artifacts
./packaging/homebrew/test-install.sh linux ./artifacts
```

Or use the build helper (creates artifacts if missing, then updates formulae):

```bash
./packaging/homebrew/brew-build.sh
./packaging/homebrew/test-install.sh macos ./artifacts
```

## Release maintenance

1. Bump `packaging/client/VERSION`.
2. Run the **Client Package** GitHub workflow (or push to `main` with `publish` enabled).
3. CI publishes GitHub Release assets and updates formula `sha256` values in this directory.

Formula URLs expect release assets:

- `thinkmay-client-linux-amd64.tar.gz`
- `thinkmay-client-linux-arm64.tar.gz`
- `thinkmay-client-darwin-arm64.zip`
- `thinkmay-client-darwin-amd64.zip`

at `https://github.com/thinkonmay/thinkmay/releases/download/v<VERSION>/`.

Homebrew picks the build for your CPU: Linux formula (`amd64` / `arm64`) and macOS cask (Apple Silicon / Intel).
