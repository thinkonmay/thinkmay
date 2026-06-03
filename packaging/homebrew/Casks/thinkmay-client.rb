# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"
  sha256 "5af0dbfa052867ce221386cc4653d9c6791236a282c276aabab52b419f692933"

  url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-darwin-arm64.zip"
  name "Thinkmay Client"
  desc "Thinkmay CloudPC desktop streaming client"
  homepage "https://thinkmay.net"

  depends_on macos: ">= :monterey"

  on_intel do
    odie "Intel Mac builds are not published. Use an Apple Silicon Mac or install the Linux/Windows client."
  end

  app "Thinkmay Client.app"

  zap trash: [
    "~/Library/Preferences/net.thinkmay.client.plist",
    "~/Library/Saved Application State/net.thinkmay.client.savedState",
  ]
end
