
require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Loquacious do
  before(:all) do
    @root_dir = File.path_from_here {'..'}
  end

  it "should report a version number" do
    Loquacious.version.should match(%r/\d+\.\d+\.\d+/)
  end

  it "finds things releative to 'lib'" do
    Loquacious.libpath(%w[loquacious config.rb]).should == File.join(@root_dir, %w[lib loquacious config.rb])
  end 
    
  it "finds things releative to 'root'" do
    Loquacious.path('Rakefile').should == File.join(@root_dir, 'Rakefile')
  end 
end

# EOF
