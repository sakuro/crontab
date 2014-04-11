require 'cron2english'

class Crontab
  # A class which represents a job line in crontab(5).
  class Entry
    # Creates a crontab(5) entry.
    #
    # * <tt>schedule</tt> A Crontab::Schedule instance.
    # * <tt>command</tt>
    # * <tt>uid</tt>
    def initialize(schedule, command, cron_definition, uid=nil)
      raise ArgumentError, 'invalid schedule' unless schedule.is_a? Schedule
      raise ArgumentError, 'invalid command' unless command.is_a? String

      @schedule = schedule.freeze
      @command = command.freeze
      @cron_definition = cron_definition.freeze
      @translation = Cron2English.parse(@cron_definition).freeze
      @uid =
        case uid
        when String
          Etc.getpwnam(uid).uid
        when Integer
          uid
        when nil
          Process.uid
        else
          raise ArgumentError, 'invalid uid'
        end
    end

    attr_reader :schedule, :command, :cron_definition, :translation, :uid
    class << self
      # Parses a string line in crontab(5) job format.
      #
      # * <tt>options[:system]</tt> when true system wide crontab is assumed
      #   and <tt>@uid</tt> is extracted from <i>line</i>.
      def parse(line, options={})
        options = { :system => false }.merge(options)
        line = line.strip
        number_of_fields = 1
        number_of_fields += line.start_with?('@') ? 1 : 5
        number_of_fields += 1 if options[:system]
        words = line.split(/\s+/, number_of_fields)
        command = words.pop
        uid = options[:system] ? words.pop : Process.uid
        cron_definition = words.first(5).join(' ')
        spec = words.join(' ')
        schedule = Crontab::Schedule.new(spec)
        new(schedule, command, cron_definition, uid)
      end
    end
  end
end
