class Crontab
  class Entry
    def initialize(schedule, command, uid=nil)
      raise ArgumentError, 'invalid schedule' unless schedule.is_a? Schedule
      raise ArgumentError, 'invalid command' unless command.is_a? String

      @schedule = schedule.freeze
      @command = command.freeze
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

    attr_reader :schedule, :command, :uid
    class << self
      def parse(line, options={})
        options = { :system => false }.merge(options)
        line = line.strip
        number_of_fields = 1
        number_of_fields += line.start_with?('@') ? 1 : 5
        number_of_fields += 1 if options[:system]
        words = line.split(/\s+/, number_of_fields)
        command = words.pop
        uid = options[:system] ? words.pop : Process.uid
        spec = words.join(' ')
        schedule = Crontab::Schedule.new(spec)
        new(schedule, command, uid)
      end
    end
  end
end
