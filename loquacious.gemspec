# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{loquacious}
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Pease"]
  s.date = %q{2009-04-05}
  s.description = %q{Descriptive configuration files for Ruby written in Ruby.  Loquacious provides a very open configuration system written in ruby and descriptions for each configuration attribute. The attributes and descriptions can be iterated over allowing for helpful information about those attributes to be displayed to the user.  In the simple case we have a file something like  Loquacious.configuration_for('app') { name 'value', :desc => "Defines the name" foo  'bar',   :desc => "FooBar" id   42,      :desc => "Ara T. Howard" }  Which can be loaded via the standard Ruby loading mechanisms  Kernel.load 'config/app.rb'  The attributes and their descriptions can be printed by using a Help object  help = Loquacious.help_for('app') help.show :values => true        # show the values for the attributes, too  Descriptions are optional, and configurations can be nested arbitrarily deep.  Loquacious.configuration_for('nested') { desc "The outermost level" a { desc "One more level in" b { desc "Finally, a real value" c 'value' } } }  config = Loquacious.configuration_for('nested')  p config.a.b.c  #=> "value"  And as you can see, descriptions can either be given inline after the value or they can appear above the attribute and value on their own line.}
  s.email = %q{tim.pease@gmail.com}
  s.extra_rdoc_files = ["History.txt", "README.rdoc"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "examples/gutters.rb", "examples/nested.rb", "examples/simple.rb", "lib/loquacious.rb", "lib/loquacious/configuration.rb", "lib/loquacious/configuration/help.rb", "lib/loquacious/configuration/iterator.rb", "lib/loquacious/core_ext/string.rb", "loquacious.gemspec", "spec/configuration_spec.rb", "spec/help_spec.rb", "spec/iterator_spec.rb", "spec/loquacious_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "spec/string_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://codeforpeople.rubyforge.org/loquacious}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{codeforpeople}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Descriptive configuration files for Ruby written in Ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>, [">= 1.2.2"])
      s.add_development_dependency(%q<bones>, [">= 2.5.0"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.2"])
      s.add_dependency(%q<bones>, [">= 2.5.0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.2"])
    s.add_dependency(%q<bones>, [">= 2.5.0"])
  end
end
