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
      sha256 "dca2ea9b23ef08e8ce9492a577c3b25580792ab8a502e4d705aa65f8ca0c45ab"
    end
    on_arm do
      url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-linux-arm64.tar.gz"
      sha256 "8438a878bfdb732ec9d59cb2fba903dac68a89231f402c44343edae5451c1937"
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
      end
    end

    test do
      assert_predicate libexec/"thinkmay-client-bin", :exist?
      assert_predicate bin/"thinkmay-client", :exist?
    end
  end
end
