# typed: false
# frozen_string_literal: true

cask "thinkmay-client" do
  version "0.1.0"
  sha256 "258a9310a9046e19c2931402a496e4d88380399a1cfc5932da030c35f5c371df"

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
