begin
  require 'rubygems/package_task'
rescue
  require 'gem/package_task'
end

namespace :gem do
  spec_files = Dir.glob('*.gemspec')
  abort("No gemspec found in project-root") if spec_files.empty?
  abort("More than one gemspec found in project-root: #{spec.join(', ')}") if spec_files.size > 1
  gem_spec    = Gem::Specification.load(spec_files.first)

  Gem::PackageTask.new(gem_spec) do |pkg|
    pkg.package_dir = 'pkg'
    pkg.need_zip    = false
    pkg.need_tar    = false
  end
end

desc "Clobbers previous products and builds the gem"
task :gem => ['gem:clobber_package', 'gem:gem']
