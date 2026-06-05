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
      sha256 "bd2f9fc86f1fcbc3d3521997dbcd37713e16175d56a1779dc29759ab0645fe63"
    end
    on_arm do
      url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-linux-arm64.tar.gz"
      sha256 "a9be25717722c771802c9f92e74597d93394856307dfd52d876f8975f5ed7727"
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
