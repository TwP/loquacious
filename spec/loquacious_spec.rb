
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Loquacious do
  before(:all) do
    @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end

  it "should report a version number" do
    Loquacious.version.should match(%r/\d+\.\d+\.\d+/)
  end

  it "finds things releative to 'lib'" do
    Loquacious.libpath(%w[loquacious config.rb]).should be == File.join(@root_dir, %w[lib loquacious config.rb])
  end

  it "finds things releative to 'root'" do
    Loquacious.path('Rakefile').should be == File.join(@root_dir, 'Rakefile')
  end

  describe "when copying configuration objects" do
    it "creates a deep copy" do
      obj = Loquacious::Configuration.new  {
              first   'foo'
              second  {
                bar   'baz'
              }
            }

      copy = Loquacious.copy obj
      copy.first = 'foobar'
      copy.second.bar = 'buz'

      obj.first.should be == 'foo'
      obj.second.bar.should be == 'baz'
      copy.first.should be == 'foobar'
      copy.second.bar.should be == 'buz'
    end

    it "looks up a configuration object by name" do
      Loquacious.config_for('by name') {
        first   'foo'
        second  {
          bar   'baz'
        }
      }

      copy = Loquacious.copy('by name')
      copy.first.should be == 'foo'
      copy.second.bar.should be == 'baz'
    end

    it "returns nil when a configuration object cannot be found" do
      Loquacious.copy('does not exist').should be_nil
    end

    it "overrides options with a block" do
      Loquacious.config_for('another by name') {
        first   'foo'
        second  {
          bar   'baz'
        }
      }

      copy = Loquacious.copy('another by name') {
        second { bar 'foobar' }
        third "hey I'm new"
      }

      copy.first.should be == 'foo'
      copy.second.bar.should be == 'foobar'
      copy.third.should be == "hey I'm new"
    end
  end
end

