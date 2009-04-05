# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'loquacious'

task :default => 'spec:specdoc'

PROJ.name = 'loquacious'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://codeforpeople.rubyforge.org/loquacious'
PROJ.version = Loquacious::VERSION
PROJ.readme_file = 'README.rdoc'
PROJ.ignore_file = '.gitignore'
PROJ.rubyforge.name = 'codeforpeople'
PROJ.rdoc.remote_dir = 'loquacious'

PROJ.spec.opts << '--color'
PROJ.ruby_opts = %w[-W0]

PROJ.ann.email[:server] = 'smtp.gmail.com'
PROJ.ann.email[:port] = 587
PROJ.ann.email[:from] = 'Tim Pease'

task 'ann:prereqs' do
  PROJ.name = 'Loquacious'
end

depend_on 'rspec'

# EOF
