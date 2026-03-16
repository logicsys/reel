require 'spec_helper'

RSpec.describe "Gemspec security" do
  let(:gemspec_content) do
    File.read(File.expand_path("../../../reel.gemspec", __FILE__))
  end

  it "does not use backtick shell execution for file listing" do
    expect(gemspec_content).not_to match(/`[^`]*git\s+ls-files/),
      "gemspec uses backtick shell execution — should use Dir.glob or git_ls_files pattern instead"
  end
end
