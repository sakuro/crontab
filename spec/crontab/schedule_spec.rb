require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'crontab/schedule'

describe Crontab::Schedule do
  describe 'when parsing spec' do
    it 'should accept spec with asterisks' do
      schedule = Crontab::Schedule.new('* * * * *')
      schedule.minutes.should == (0..59).to_a and
      schedule.hours.should == (0..23).to_a and
      schedule.day_of_months.should == (1..31).to_a and
      schedule.months.should == (1..12).to_a and
      schedule.day_of_weeks.should == (0..6).to_a
    end

    it 'should accept spec with simple numbers' do
      schedule = Crontab::Schedule.new('0 0 1 1 0')
      schedule.minutes.should == [0] and
      schedule.hours.should == [0] and
      schedule.day_of_months.should == [1] and
      schedule.months.should == [1] and
      schedule.day_of_weeks.should == [0]
    end

    it 'should accept spec with names(Jan, Sun etc.)' do
      schedule = Crontab::Schedule.new('0 0 1 Jan sUn')
      schedule.minutes.should == [0] and
      schedule.hours.should == [0] and
      schedule.day_of_months.should == [1] and
      schedule.months.should == [1] and
      schedule.day_of_weeks.should == [0]
    end

    it 'should accept spec with ranges(N-N)' do
      schedule = Crontab::Schedule.new('0-1 0-1 1-2 1-2 0-1')
      schedule.minutes.should == [0, 1] and
      schedule.hours.should == [0, 1] and
      schedule.day_of_months.should == [1, 2] and
      schedule.months.should == [1, 2] and
      schedule.day_of_weeks.should == [0, 1]
    end

    it 'should accept spec with lists(comma separaged ranges/numbers)' do
      schedule = Crontab::Schedule.new('0,10,20 0,10,20 1,11,21 1,3,5 0,4,5,6')
      schedule.minutes.should == [0, 10, 20] and
      schedule.hours.should == [0, 10, 20] and
      schedule.day_of_months.should == [1, 11, 21] and
      schedule.months.should == [1, 3, 5] and
      schedule.day_of_weeks.should == [0, 4, 5, 6]

      schedule = Crontab::Schedule.new('0,1-5,10 0,1-5,10 1,2-5,10 1,2-4,10 0,1-3,7')
      schedule.minutes.should == [0, 1, 2, 3, 4, 5, 10] and
      schedule.hours.should == [0, 1, 2, 3, 4, 5, 10] and
      schedule.day_of_months.should == [1, 2, 3, 4, 5, 10] and
      schedule.months.should == [1, 2, 3, 4, 10] and
      schedule.day_of_weeks.should == [0, 1, 2, 3]
    end

    it 'should accept spec with steps(range/STEP or */STEP)' do
      schedule = Crontab::Schedule.new('0-30/10 1-20/5 5-30/7 4-10/2 1-5/2')
      schedule.minutes.should == [0, 10, 20, 30] and
      schedule.hours.should == [1, 6, 11, 16 ] and
      schedule.day_of_months.should == [5, 12, 19, 26 ] and
      schedule.months.should == [4, 6, 8, 10] and
      schedule.day_of_weeks.should == [1, 3, 5]

      schedule = Crontab::Schedule.new('*/25 */5 */10 */4 */2')
      schedule.minutes.should == [0, 25, 50] and
      schedule.hours.should == [0, 5, 10, 15, 20] and
      schedule.day_of_months.should == [1, 11, 21, 31] and
      schedule.months.should == [1, 5, 9] and
      schedule.day_of_weeks.should == [0, 2, 4, 6]
    end

    it 'should reject spec with incorrect number of fields' do
      lambda { Crontab::Schedule.new }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new(nil) }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('x') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('* * * *') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('* * * * * *') }.should raise_error(ArgumentError)
    end

    it 'should reject spec with incorrect values' do
      lambda { Crontab::Schedule.new('x 0 1 0 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('-1 0 1 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('60 0 1 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 24 1 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 32 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 13 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 1 8') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 Mon 8') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('Jan Sun 1 1 8') }.should raise_error(ArgumentError)
    end

    it 'should reject spec with names in lists and ranges' do
      lambda { Crontab::Schedule.new('0 0 1 Jan-Feb *') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 Jan,Feb *') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 * Sun-Fri') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 * Sun,Fri') }.should raise_error(ArgumentError)
    end

    it 'should reject spec with simple numbers with step' do
      lambda { Crontab::Schedule.new('0/2 0 1 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0/2 1 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1/2 1 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 1/2 0') }.should raise_error(ArgumentError)
      lambda { Crontab::Schedule.new('0 0 1 1 0/2') }.should raise_error(ArgumentError)
    end

    it 'should accept symblic specs' do
      start = Time.now
      Crontab::Schedule.new('@yearly', start).should == Crontab::Schedule.new('0 0 1 1 *', start) and
      Crontab::Schedule.new('@annually', start).should == Crontab::Schedule.new('0 0 1 1 *', start) and
      Crontab::Schedule.new('@monthly', start).should == Crontab::Schedule.new('0 0 1 * *', start) and
      Crontab::Schedule.new('@weekly', start).should == Crontab::Schedule.new('0 0 * * 0', start) and
      Crontab::Schedule.new('@daily', start).should == Crontab::Schedule.new('0 0 * * *', start) and
      Crontab::Schedule.new('@midnight', start).should == Crontab::Schedule.new('0 0 * * *', start) and
      Crontab::Schedule.new('@hourly', start).should == Crontab::Schedule.new('0 * * * *', start)
    end

    it 'should reject @reboot' do
      lambda { Crontab::Schedule.new('@reboot') }.should raise_error(NotImplementedError)
    end

    it 'should reject unknown symbolic spec' do
      lambda { Crontab::Schedule.new('@unknown') }.should raise_error(ArgumentError)
    end

    it 'should ignore leading/trailing whitespaces' do
      lambda {
        Crontab::Schedule.new(' @daily')
        Crontab::Schedule.new('@daily ')
        Crontab::Schedule.new(' * * * * *')
        Crontab::Schedule.new('* * * * * ')
      }.should_not raise_error
    end
  end

  describe 'when accessing' do
    it 'should accept Time as start parameter' do
      start = Time.local(2009, 3, 25, 10, 20, 30)
      lambda {
        schedule = Crontab::Schedule.new('* * * * *', start)
        schedule.start.should == start
      }.should_not raise_error
    end

    it 'should accept Date as start parameter' do
      start = Date.new(2009, 3, 25)
      lambda {
        schedule = Crontab::Schedule.new('* * * * *', start)
        schedule.start.should == Time.local(start.year, start.month, start.day)
      }.should_not raise_error
    end

    it 'should set start to given Time' do
      initial_start = Time.local(2009, 3, 25, 10, 20, 30)
      schedule = Crontab::Schedule.new('* * * * *', initial_start)
      schedule.start.should == initial_start and

      new_start = Time.local(2009, 4, 25, 11, 21, 31)
      schedule.start = new_start
      schedule.start.should == new_start
    end

    it 'should set start to given Date' do
      initial_start = Time.local(2009, 3, 25, 10, 20, 30)
      schedule = Crontab::Schedule.new('* * * * *', initial_start)
      schedule.start.should == initial_start and

      new_start = Date.new(2009, 4, 25)
      new_start_as_time = Time.local(new_start.year, new_start.month, new_start.day)
      schedule.start = new_start
      schedule.start.should == new_start_as_time
    end
  end

  describe 'when duplicating' do
    it 'should return a new schedule starting at given Time' do
      initial_start = Time.local(2009, 3, 25, 10, 20, 30)
      schedule = Crontab::Schedule.new('* * * * *', initial_start)
      new_start = Time.local(2009, 4, 25, 11, 21, 31)
      new_schedule = schedule.from(new_start)

      new_schedule.object_id.should_not == schedule.object_id and
      new_schedule.hash.should_not == schedule.hash and
      new_schedule.should_not == schedule and

      new_schedule.start.should == new_start and
      new_schedule.minutes.should == schedule.minutes and
      new_schedule.hours.should == schedule.hours and
      new_schedule.day_of_months.should == schedule.day_of_months and
      new_schedule.months.should == schedule.months and
      new_schedule.day_of_weeks.should == schedule.day_of_weeks and
      new_schedule.send(:day_of_months_given?).should == schedule.send(:day_of_months_given?) and
      new_schedule.send(:day_of_weeks_given?).should == schedule.send(:day_of_weeks_given?)
    end

    it 'should return a new schedule starting at given Date' do
      initial_start = Time.local(2009, 3, 25, 10, 20, 30)
      schedule = Crontab::Schedule.new('* * * * *', initial_start)
      new_start = Date.new(2009, 4, 25)
      new_start_as_time = Time.local(new_start.year, new_start.month, new_start.day)
      new_schedule = schedule.from(new_start)

      new_schedule.object_id.should_not == schedule.object_id and
      new_schedule.hash.should_not == schedule.hash and
      new_schedule.should_not == schedule and

      new_schedule.start.should == new_start_as_time and
      new_schedule.minutes.should == schedule.minutes and
      new_schedule.hours.should == schedule.hours and
      new_schedule.day_of_months.should == schedule.day_of_months and
      new_schedule.months.should == schedule.months and
      new_schedule.day_of_weeks.should == schedule.day_of_weeks and
      new_schedule.send(:day_of_months_given?).should == schedule.send(:day_of_months_given?) and
      new_schedule.send(:day_of_weeks_given?).should == schedule.send(:day_of_weeks_given?)
    end
  end

  describe 'when comparing' do
    it 'should equal to other if and only if both are created from equivalent spec and start time' do
      start = Time.now
      Crontab::Schedule.new('0 0 1 1 0', start).should == Crontab::Schedule.new('0 0 1 1 0', start) and
      Crontab::Schedule.new('0 0 1 1 0', start).should == Crontab::Schedule.new('0 0 1 Jan 0', start) and
      Crontab::Schedule.new('0 0 1 1 0', start).should == Crontab::Schedule.new('0 0 1 1 Sun', start) and

      Crontab::Schedule.new('0 0 1 1 0', start).should_not == Crontab::Schedule.new('1 0 1 1 0', start) and
      Crontab::Schedule.new('0 0 1 1 0', start).should_not == Crontab::Schedule.new('0 1 1 1 0', start) and
      Crontab::Schedule.new('0 0 1 1 0', start).should_not == Crontab::Schedule.new('0 0 2 1 0', start) and
      Crontab::Schedule.new('0 0 1 1 0', start).should_not == Crontab::Schedule.new('0 0 1 2 0', start) and
      Crontab::Schedule.new('0 0 1 1 0', start).should_not == Crontab::Schedule.new('0 0 1 1 1', start) and

      Crontab::Schedule.new('0 0 1-5 1 0', start).should == Crontab::Schedule.new('0 0 1,2,3,4,5 1 0', start) and
      Crontab::Schedule.new('0 0 1 1 0-4', start).should == Crontab::Schedule.new('0 0 1 1 0,1,2,3,4', start)
    end
  end

  describe 'when enumerating' do
    it 'should return given number of timings' do
      schedule = Crontab::Schedule.new('* * * * *', Time.local(2009, 3, 8, 4, 30, 15))
      expected = [
        Time.local(2009, 3, 8, 4, 31),
        Time.local(2009, 3, 8, 4, 32),
        Time.local(2009, 3, 8, 4, 33),
        Time.local(2009, 3, 8, 4, 34),
        Time.local(2009, 3, 8, 4, 35),
      ]
      schedule.first(expected.size).should == expected and

      schedule = Crontab::Schedule.new('5 10 3-5,10 * *', Time.local(2009, 3, 8, 10, 30, 15))
      expected = [
        Time.local(2009, 3, 10, 10, 5),
        Time.local(2009, 4,  3, 10, 5),
        Time.local(2009, 4,  4, 10, 5),
        Time.local(2009, 4,  5, 10, 5),
        Time.local(2009, 4, 10, 10, 5),
        Time.local(2009, 5,  3, 10, 5),
        Time.local(2009, 5,  4, 10, 5),
        Time.local(2009, 5,  5, 10, 5),
        Time.local(2009, 5, 10, 10, 5),
        Time.local(2009, 6,  3, 10, 5),
      ]
      schedule.first(expected.size).should == expected
    end

    it 'should return timings matching day of month or day of week' do
      schedule = Crontab::Schedule.new('0 0 1,10,11 3 0,1', Time.local(2009, 3, 8, 10, 30, 15))
      expected = [
        Time.local(2009, 3,  9, 0, 0),
        Time.local(2009, 3, 10, 0, 0),
        Time.local(2009, 3, 11, 0, 0),
        Time.local(2009, 3, 15, 0, 0),
        Time.local(2009, 3, 16, 0, 0),
        Time.local(2009, 3, 22, 0, 0),
        Time.local(2009, 3, 23, 0, 0),
        Time.local(2009, 3, 29, 0, 0),
        Time.local(2009, 3, 30, 0, 0),
      ]
      schedule.first(expected.size).should == expected and

      schedule = Crontab::Schedule.new('0 0 1,10,11 3 *', Time.local(2009, 3, 8, 10, 30, 15))
      expected = [
        Time.local(2009, 3, 10, 0, 0),
        Time.local(2009, 3, 11, 0, 0),
      ]
      schedule.first(expected.size).should == expected and

      schedule = Crontab::Schedule.new('0 0 * 3 0,1', Time.local(2009, 3, 8, 10, 30, 15))
      expected = [
        Time.local(2009, 3,  9, 0, 0),
        Time.local(2009, 3, 15, 0, 0),
        Time.local(2009, 3, 16, 0, 0),
        Time.local(2009, 3, 22, 0, 0),
        Time.local(2009, 3, 23, 0, 0),
        Time.local(2009, 3, 29, 0, 0),
        Time.local(2009, 3, 30, 0, 0),
      ]
      schedule.first(expected.size).should == expected
    end

    it 'should return timings until given time' do
      schedule = Crontab::Schedule.new('* * * * *', Time.local(2009, 3, 8, 4, 30, 15))
      expected = [
        Time.local(2009, 3, 8, 4, 31),
        Time.local(2009, 3, 8, 4, 32),
        Time.local(2009, 3, 8, 4, 33),
        Time.local(2009, 3, 8, 4, 34),
        Time.local(2009, 3, 8, 4, 35),
        Time.local(2009, 3, 8, 4, 36),
        Time.local(2009, 3, 8, 4, 37),
        Time.local(2009, 3, 8, 4, 38),
        Time.local(2009, 3, 8, 4, 39),
        Time.local(2009, 3, 8, 4, 40),
      ]
      schedule.until(Time.local(2009, 3, 8, 4, 40, 10)).should == expected and

      result = []
      schedule.until(Time.local(2009, 3, 8, 4, 40, 10)) do |t|
        result << t
      end
      result.should == expected and

      schedule = Crontab::Schedule.new('*/20 0 21 * *', Time.local(2009, 3, 8, 4, 30, 15))
      expected = [
        Time.local(2009, 3, 21, 0,  0),
        Time.local(2009, 3, 21, 0, 20),
        Time.local(2009, 3, 21, 0, 40),
        Time.local(2009, 4, 21, 0,  0),
        Time.local(2009, 4, 21, 0, 20),
        Time.local(2009, 4, 21, 0, 40),
        Time.local(2009, 5, 21, 0, 00),
        Time.local(2009, 5, 21, 0, 20),
        Time.local(2009, 5, 21, 0, 40),
      ]
      schedule.until(Time.local(2009, 6, 1)).should == expected
    end

    it 'should exclude invalid day of month' do
      schedule = Crontab::Schedule.new('5 0 27,29,31 * *', Time.local(2009, 1, 1, 10, 30, 15))
      expected = [
        Time.local(2009, 1, 27, 0, 5),
        Time.local(2009, 1, 29, 0, 5),
        Time.local(2009, 1, 31, 0, 5),
        Time.local(2009, 2, 27, 0, 5),
        # Time.local(2009, 2, 29, 0, 5), # should exclude this!
        # Time.local(2009, 2, 31, 0, 5), # should exclude this!
        Time.local(2009, 3, 27, 0, 5),
        Time.local(2009, 3, 29, 0, 5),
        Time.local(2009, 3, 31, 0, 5),
      ]

      schedule.first(expected.size).should == expected
    end
  end
end
