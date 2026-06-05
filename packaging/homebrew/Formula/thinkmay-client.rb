# typed: false
# frozen_string_literal: true

# Linux: prebuilt tarball with bundled FFmpeg/SDL2 libraries.
# macOS: use the cask instead — brew install --cask thinkmay-client
class ThinkmayClient < Formula
  desc "Thinkmay CloudPC desktop streaming client"
  homepage "https://thinkmay.net"
  version "0.1.0"
  license :cannot_represent

  on_macos do
    odie "thinkmay-client is installed as a macOS app. Run: brew install --cask thinkmay-client"
  end

  on_linux do
    on_intel do
      url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-linux-amd64.tar.gz"
      sha256 "31f4ccb48364867e6a748a691f76f6ccc3661818e8564bdf7e7456d899cc69d6"
    end
    on_arm do
      url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-linux-arm64.tar.gz"
      sha256 "75891a4f72c0b87aa398781af891d1a22e06ab83beebb2d6563f4ff01f04da4e"
    end

    def linux_pkg_dir
      arch = Hardware::CPU.arm? ? "arm64" : "amd64"
      root = buildpath/"thinkmay-client-linux-#{arch}"
      root.directory? ? root : buildpath
    end

    def install
      cd linux_pkg_dir do
        (libexec/"lib").install Dir["lib/*"]
        libexec.install "thinkmay-client-bin"
        (bin/"thinkmay-client").write <<~SHELL
          #!/bin/bash
          export LD_LIBRARY_PATH="#{libexec}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          exec "#{libexec}/thinkmay-client-bin" "$@"
        SHELL
        chmod 0755, bin/"thinkmay-client"
        (share/"applications").install "thinkmay-client.desktop"
        (share/"icons").install "icons/hicolor"
      end
    end

    test do
      assert_predicate libexec/"thinkmay-client-bin", :exist?
      assert_predicate bin/"thinkmay-client", :exist?
      assert_predicate share/"applications/thinkmay-client.desktop", :exist?
      [48, 128, 256, 512].each do |size|
        assert_predicate share/"icons/hicolor/#{size}x#{size}/apps/thinkmay-client.png", :exist?
      end
    end
  end
end
