require 'rubygems/command_manager'
require 'gem/commands/new_command'

Gem::CommandManager.instance.register_command :new
