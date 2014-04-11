Gem::Specification.new do |s|
  s.name = 'crontab'
  s.version = '0.0.3'
  s.author = 'OZAWA Sakuro'
  s.email = 'github@2238club.org'
  s.homepage = 'http://github.com/sakuro/crontab'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A crontab(5) entry parser'
  s.files = [
    'lib/crontab.rb',
    'lib/crontab/entry.rb',
    'lib/crontab/schedule.rb',
    'spec/crontab_spec.rb',
    'spec/crontab/entry_spec.rb',
    'spec/crontab/schedule_spec.rb',
    'crontab.gemspec',
    'Rakefile',
    'README.rdoc'
  ]
  s.has_rdoc = true
  s.rubyforge_project = 'n/a'
end
