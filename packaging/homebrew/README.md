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

Build client packages with CI or locally, refresh checksums, then install from the checkout:

```bash
# After client-package artifacts exist under ./artifacts/
./packaging/homebrew/update-formulae.sh ./artifacts

# macOS
brew install --cask ./packaging/homebrew/Casks/thinkmay-client.rb

# Linux (Homebrew on Linux)
brew install ./packaging/homebrew/Formula/thinkmay-client.rb
```

Or use the helper script:

```bash
./packaging/homebrew/brew-build.sh
```

## Release maintenance

1. Bump `packaging/client/VERSION`.
2. Run the **Client Package** GitHub workflow (or push to `main` with `publish` enabled).
3. CI publishes GitHub Release assets and updates formula `sha256` values in this directory.

Formula URLs expect release assets:

- `thinkmay-client-linux-amd64.tar.gz`
- `thinkmay-client-darwin.zip`

at `https://github.com/thinkonmay/thinkmay/releases/download/v<VERSION>/`.
