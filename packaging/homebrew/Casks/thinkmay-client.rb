# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"
  sha256 "6247298d4ef24a8d7653de5aa845e31419be232ccb8776f9cc434333ef2ae7e4"

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
