# encoding: utf-8

Gem::Specification.new do |s|
  s.name                      = "gem-new"
  s.version                   = "0.2.0"
  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1")
  s.authors                   = ["Stefan Rusterholz"]
  s.description               = <<-DESCRIPTION.chomp
    Gem-new is a gem command plugin that allows you to easily create a new gem.
  DESCRIPTION
  s.summary                   = <<-SUMMARY.chomp
    Create new gems easily
  SUMMARY
  s.email                     = "stefan.rusterholz@gmail.com"
  s.files                     = 
    Dir['data/**/*'] +
    Dir['data/**/.gitkeep'] +
    Dir['lib/**/*'] +
    Dir['rake/**/*'] +
    Dir['test/**/*'] +
    %w[
      HISTORY.markdown
      Rakefile
      README.markdown
    ]
  s.homepage                  = "https://github.com/apeiros/gem-new"
  s.require_paths             = %w[lib]
  s.rubygems_version          = "1.3.1"
  s.specification_version     = 3
end
