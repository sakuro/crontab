require 'crontab/schedule'
require 'crontab/entry'

# A class which represents crontab(5) content.
class Crontab
  class << self
    # Parses a crontab(5) text.
    #
    # * <tt>src</tt> string in crontab(5) format
    def parse(src)
      entries = []
      env = {}
      src.lines.each do |line|
        line.strip!
        case line
        when /\A[\d*]/
          entries << Crontab::Entry.parse(line)
        when /\A([A-Z][A-Z0-9_]*)\s*=\s*/, /\A"([A-Z][A-Z0-9_]*)"\s*=\s*/, /\A'([A-Z][A-Z0-9_]*)'\s*=\s*/
          name = $1
          value = $'
          value = $1 if /\A'(.*)'\z/ =~ value or /\A"(.*)"\z/ =~ value
          env[name] = value
        end
      end
      new(entries, env)
    end
  end

  def initialize(entries, env)
    @entries = entries.dup.freeze
    @env = env.dup.freeze
  end
  attr_reader :entries, :env
end
