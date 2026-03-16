require 'spec_helper'

RSpec.describe "HTTPS verify_mode default" do
  it "logs a warning when defaulting to VERIFY_NONE" do
    source = File.read(File.expand_path("../../../lib/reel/server/https.rb", __FILE__))

    # When defaulting to VERIFY_NONE, there should be a warning logged
    # to alert operators that peer verification is disabled
    verify_none_section = source[/VERIFY_NONE.*?$/m]
    expect(source).to match(/warn.*VERIFY_NONE|warn.*verify|Logger.*verify/im),
      "HTTPS server defaults to VERIFY_NONE without logging a warning — " \
      "operators should be alerted when peer verification is disabled"
  end
end
