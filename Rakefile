require 'rake/gempackagetask'
require 'spec/rake/spectask'

task :default => :spec

spec = Gem::Specification.load('crontab.gemspec')

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar_bz2 = true
end

Spec::Rake::SpecTask.new do |t|
  t.warning = true
  t.rcov = false
end
