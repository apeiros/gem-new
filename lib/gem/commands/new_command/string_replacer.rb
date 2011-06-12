class Gem::Commands::NewCommand < Gem::Command
  class StringReplacer
    def self.replace(string, variables)
      new(variables).replace(string)
    end

    def initialize(variables)
      @variables = Hash[variables.map { |k,v| [k.to_s, v.to_s] }] # convert keys and values to strings
      @pattern   = Regexp.union(@variables.keys.map { |var| Regexp.escape(var) })
    end

    def replace(string)
      string.gsub(@pattern, @variables)
    end
  end
end
