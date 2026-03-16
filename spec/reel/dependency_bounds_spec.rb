require 'spec_helper'

RSpec.describe "Dependency version bounds" do
  let(:gemspec_content) do
    File.read(File.expand_path("../../../reel.gemspec", __FILE__))
  end

  it "uses bounded version constraints for runtime dependencies" do
    # Extract runtime dependency lines
    runtime_deps = gemspec_content.lines.select { |l| l =~ /add_runtime_dependency/ }

    runtime_deps.each do |dep|
      # Each runtime dependency should use ~> (pessimistic) rather than >= (unbounded)
      expect(dep).to match(/~>/),
        "Unbounded runtime dependency found: #{dep.strip}\n" \
        "Use pessimistic version constraint (~>) to prevent unexpected breaking changes"
    end
  end
end
