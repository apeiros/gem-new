# encoding: utf-8

class Gem::Commands::NewCommand < Gem::Command
  class StringReplacer
    def self.replace(string, variables)
      new(variables).replace(string)
    end

    def initialize(variables)
      @variables = Hash[variables.map { |k,v| [k.to_s, v.to_s] }] # convert keys and values to strings
      @pattern   = Regexp.union(@variables.keys.map { |var| Regexp.escape(var) })
    end

    begin
      "hi".gsub(/./u, {})
    rescue TypeError # ruby 1.8
      def replace(string)
        string.gsub(@pattern) { |m| @variables[m] }
      end
    else # ruby 1.9
      def replace(string)
        string.gsub(@pattern, @variables)
      end
    end
  end
end
