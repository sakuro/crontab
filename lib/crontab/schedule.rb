require 'date'

class Crontab

  class Schedule

    MONTH_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
    DAY_OF_WEEK_NAMES = %w(Sun Mon Tue Wed Thu Fri Sat)
    DAYS_IN_MONTH = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    def initialize(spec, start=Time.now)
      raise ArgumentError, 'empty spec' if spec == '' or spec.nil?
      @start = ensure_time(start)
      spec = spec.strip
      if spec.start_with?('@')
        parse_symbolic_spec(spec)
      else
        parse_spec(spec)
      end
    end

    def ==(other)
      self.minutes == other.minutes &&
      self.hours == other.hours &&
      self.day_of_months == other.day_of_months &&
      self.months == other.months &&
      self.day_of_months_given? == other.day_of_months_given? &&
      self.day_of_weeks == other.day_of_weeks &&
      self.day_of_weeks_given? == other.day_of_weeks_given? &&
      self.start == other.start
    end

    def hash
      [ minutes, hours, day_of_months, months, day_of_weeks, day_of_months_given?, day_of_weeks_given?, start ].map(&:hash).inject(:^)
    end

    attr_reader :minutes, :hours, :day_of_months, :months, :day_of_weeks, :start

    def start=(time_or_date)
      @start = ensure_time(time_or_date)
    end

    def from(time_or_date)
      self.dup.tap {|new_schedule| new_schedule.start = ensure_time(time_or_date) }
    end

    def day_of_months_given?
      !!@day_of_months_given # ensures boolean
    end
    protected :day_of_months_given?

    def day_of_weeks_given?
      !!@day_of_weeks_given # ensures boolean
    end
    protected :day_of_weeks_given?

    def each
      return to_enum unless block_given?
      year = @start.year
      seeking = Hash.new {|h,k| h[k] = true }
      loop do
        @months.each do |month|
          next if seeking[:month] and month < @start.month and @start.month <= @months.max
          seeking[:month] = false
          days = matching_days(year, month)
          days.each do |day_of_month|
            next if seeking[:day_of_month] and day_of_month < @start.day and @start.day <= days.max
            seeking[:day_of_month] = false
            @hours.each do |hour|
              next if seeking[:hour] and hour < @start.hour and @start.hour <= @hours.max
              seeking[:hour] = false
              @minutes.each do |minute|
                begin
                  t = Time.local(year, month, day_of_month, hour, minute)
                rescue ArgumentError
                  raise StopIteration
                end
                yield(t) if @start <= t
              end
            end
          end
        end
        year += 1
      end
    end

    include Enumerable

    def until(time_or_date)
      time = ensure_time(time_or_date)
      if block_given?
        each do |t|
          break if time < t
          yield(t)
        end
      else
        inject([]) do |timings, t|
          break timings if time < t
          timings << t
        end
      end
    end

    private

    def parse_spec(spec)
      args = spec.split(/\s+/)
      raise ArgumentError, 'wrong number of spec fields: %d' % args.size unless args.size == 5
      @minutes = parse_spec_field(args[0], 0..59, :accept_name => false)
      @hours = parse_spec_field(args[1], 0..23, :accept_name => false)
      @day_of_months = parse_spec_field(args[2], 1..31, :accept_name => false)
      @day_of_months_given = args[2] != '*'
      @months = parse_spec_field(args[3], 1..12, :names => MONTH_NAMES, :base => 1, :accept_name => true)
      @day_of_weeks = parse_spec_field(args[4], 0..6, :names => DAY_OF_WEEK_NAMES, :base => 0, :accept_name => true, :allow_end => true)
      @day_of_weeks_given = args[4] != '*'
    end

    def parse_symbolic_spec(spec)
      case spec
      when '@yearly', '@annually'
        parse_spec('0 0 1 1 *')
      when '@monthly'
        parse_spec('0 0 1 * *')
      when '@weekly'
        parse_spec('0 0 * * 0')
      when '@daily', '@midnight'
        parse_spec('0 0 * * *')
      when '@hourly'
        parse_spec('0 * * * *')
      when '@reboot'
        raise NotImplementedError, '@reboot is not supported'
      else
        raise ArgumentError, 'unknown crontab spec: %s' % spec
      end
    end

    def parse_spec_field(spec, range, options={})
      options = { :accept_name => true, :allow_end => false }.merge(options)
      case spec
      when '*'
        range.to_a
      when /\A\d+\z/
        [ parse_number(spec, range, options) ]
      when /\A[a-z]{3}\z/i
        [ parse_name(spec, range, options) ]
      when /\A(\d+)-(\d+)\z/i
        parse_range($1, $2, range, options.merge(:accept_name => false))
      when /,/
        parse_list(spec.split(/,/), range, options.merge(:accept_name => false))
      when /\A(\*|\d+-\d+)\/(\d+)\z/
        parse_step($1, $2.to_i, range, options.merge(:accept_name => false))
      else
        raise ArgumentError, 'wrong spec format: %s' % spec
      end.tap do |result|
        if options[:allow_end] && result.include?(range.first) && result.include?(range.last.succ)
          result.delete(range.last.succ)
        end
      end.sort.uniq.freeze
    end

    def parse_number(spec, range, options)
      v = spec.to_i
      return v if range.include?(v) or options[:allow_end] && range.last.succ == v
      raise ArgumentError, 'argument out of range: %s' % spec
    end

    def parse_name(spec, range, options)
      raise ArgumentError, 'names not allowed in this field: %s' % spec unless options[:names] and options[:base]
      raise ArgumentError, 'names not allowed in this context: %s' % spec unless options[:accept_name]
      v = options[:names].index {|name| name.downcase == spec.downcase }
      base = options[:base]
      return v + base if v && range.include?(v + base)
      raise ArgumentError, 'argument out of range: %s' % spec
    end

    def parse_range(from, to, range, options)
      from = parse_number(from, range, options[:allow_end])
      to = parse_number(to, range, options[:allow_end])
      raise ArgumentError, 'start is after or equal to end: %s' % spec unless from < to
      (from..to).to_a
    end

    def parse_list(specs, range, options)
      specs.map{|spec| parse_spec_field(spec, range, options) }.flatten
    end

    def parse_step(first, step, range, options)
      v = parse_spec_field(first, range, options)
      v.first.step(v.size == 1 ? range.last : v.last, step).to_a
    end

    def matching_days(year, month)
      days = number_of_days(year, month)
      (1..days).select do |day|
        wday = day_of_week(year, month, day)
        if day_of_months_given?
          if day_of_weeks_given?
            @day_of_months.include?(day) or @day_of_weeks.include?(wday)
          else
            @day_of_months.include?(day)
          end
        else
          if day_of_weeks_given?
            @day_of_weeks.include?(wday)
          else
            true
          end
        end
      end
    end

    def ensure_time(time_or_date)
      time_or_date.is_a?(Date) ? Time.local(time_or_date.year, time_or_date.month, time_or_date.day) : time_or_date
    end

    def number_of_days(year, month)
      days = DAYS_IN_MONTH[month]
      days += 1 if month == 2 && (year % 4 == 0 && year % 100 != 0 || year % 400 == 0)
      days
    end

    def day_of_week(year, month, day)
      Date.new(year, month, day).wday
    end
  end

end
