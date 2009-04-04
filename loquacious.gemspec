# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{loquacious}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Pease"]
  s.date = %q{2009-04-04}
  s.description = %q{Descriptive configuration files for Ruby using Ruby.  You've written a great new piece of code that is configurable but comes with sensible defaults so that others can start using it quickly. Now it is time to document all those configuration options so your adoring fans can wield your code in anger.  This is where Loquacious comes in -- a configuration system with baked in documentation and help. Loquacious allows you to describe your configuration options and use those descriptions to print pretty help messages.}
  s.email = %q{tim.pease@gmail.com}
  s.extra_rdoc_files = ["History.txt", "README.rdoc"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "examples/gutters.rb", "examples/nested.rb", "examples/simple.rb", "lib/loquacious.rb", "lib/loquacious/configuration.rb", "lib/loquacious/configuration/help.rb", "lib/loquacious/configuration/iterator.rb", "lib/loquacious/core_ext/string.rb", "loquacious.gemspec", "spec/configuration_spec.rb", "spec/help_spec.rb", "spec/iterator_spec.rb", "spec/loquacious_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "spec/string_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://codeforpeople.rubyforge.org/loquacious}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{codeforpeople}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Descriptive configuration files for Ruby using Ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>, [">= 1.1.12"])
      s.add_development_dependency(%q<bones>, [">= 2.4.2"])
    else
      s.add_dependency(%q<rspec>, [">= 1.1.12"])
      s.add_dependency(%q<bones>, [">= 2.4.2"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.1.12"])
    s.add_dependency(%q<bones>, [">= 2.4.2"])
  end
end
