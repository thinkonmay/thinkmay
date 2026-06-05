# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"
  sha256 "2aca0971248debecd91c8e12039043550ac61214994074e9041678356769aaad"

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
