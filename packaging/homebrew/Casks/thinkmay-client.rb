# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"
  sha256 "30cc4e518d65a5f5e304b69b2271ae01f9bec86b76a37d0d4bf1efb40ecd2256"

  url "https://github.com/thinkonmay/thinkmay/releases/download/v#{version}/thinkmay-client-darwin.zip"
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
