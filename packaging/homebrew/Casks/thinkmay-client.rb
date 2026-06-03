# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"

  on_arm do
    url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-darwin-arm64.zip"
    sha256 "de11a805e4710d070a6afca8d7e4d62034481146319d0eac1c3c2e87fc5c5a7f"
  end
  on_intel do
    url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-darwin-amd64.zip"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  name "Thinkmay Client"
  desc "Thinkmay CloudPC desktop streaming client"
  homepage "https://thinkmay.net"

  depends_on macos: ">= :monterey"

  app "Thinkmay Client.app"

  zap trash: [
    "~/Library/Preferences/net.thinkmay.client.plist",
    "~/Library/Saved Application State/net.thinkmay.client.savedState",
  ]
end
