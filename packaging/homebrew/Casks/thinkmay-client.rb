# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"
  sha256 "803b09c6396688f94b63a6f0725da8e022adc46859900491a60cc10c71abc8d9"

  url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-darwin-arm64.zip"
  name "Thinkmay Client"
  desc "Thinkmay CloudPC desktop streaming client"
  homepage "https://thinkmay.net"

  depends_on macos: ">= :monterey"

  on_macos do
    on_intel do
      odie "Intel Mac builds are not published. Use an Apple Silicon Mac or install the Linux/Windows client."
    end

    app "Thinkmay Client.app"

    zap trash: [
      "~/Library/Preferences/net.thinkmay.client.plist",
      "~/Library/Saved Application State/net.thinkmay.client.savedState",
    ]
  end
end
