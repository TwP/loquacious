
begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'loquacious'

task :default => 'spec:specdoc'
task 'gem:release' => 'spec:run'

Bones {
  name         'loquacious'
  authors      'Tim Pease'
  email        'tim.pease@gmail.com'
  url          'http://gemcutter.org/gems/loquacious'
  version      Loquacious::VERSION
  readme_file  'README.rdoc'
  ignore_file  '.gitignore'
  ruby_opts    %w[-W0]
  spec.opts << '--color'
  rubyforge.name 'codeforpeople'

  depend_on 'rspec',        :development => true
  depend_on 'bones-git',    :development => true
  depend_on 'bones-extras', :development => true

  use_gmail
  enable_sudo
}


task 'ann:prereqs' do
  Bones.config.name = 'Loquacious'
end

