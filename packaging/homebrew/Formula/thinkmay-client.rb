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
      sha256 "b0cd3d6ec2fd594d0e2f956f77e398b5106f6559884718ff8b36fe579a02833a"
    end
    on_arm do
      odie "Linux ARM64 builds are not published yet"
    end

    def install
      pkg = "thinkmay-client-linux-amd64"
      cd pkg do
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
