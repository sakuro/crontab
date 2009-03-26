require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'crontab/entry'
require 'crontab/schedule'

describe Crontab::Entry do
  describe 'when instantiating' do
    before :each do
      @schedule = Crontab::Schedule.new('0 0 * * *') # @daily
      @command = 'echo hello'
    end

    it 'should accpet Crontab::Schedule and command String' do
      entry = Crontab::Entry.new(@schedule, @command)
      entry.uid.should == Process.uid
    end

    it 'should accpet Crontab::Schedule, command String and user String' do
      uid = Process.uid
      user = Etc.getpwuid(uid)
      entry = Crontab::Entry.new(@schedule, @command, user.name)
      entry.uid.should == uid
    end

    it 'should accpet Crontab::Schedule, command String and user ID' do
      uid = Process.uid
      entry = Crontab::Entry.new(@schedule, @command, uid)
      entry.uid.should == uid
    end

    it 'should reject invalid arguments' do
      lambda { Crontab::Entry.new(@schedule, nil) }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new(@schedule, Object.new) }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new(@schedule) }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new(nil, @command) }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new(Object.new, @command) }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new(@command) }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new }.should raise_error(ArgumentError)
      lambda { Crontab::Entry.new(nil) }.should raise_error(ArgumentError)
    end

    describe 'by parsing' do
      it 'should parse crontab entry line' do
        entry = Crontab::Entry.parse('0 0 * * * echo hello')
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
        entry.uid.should == Process.uid

        entry = Crontab::Entry.parse('0 0 * * * echo hello', false)
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
        entry.uid.should == Process.uid
      end

      it 'should parse crontab entry line with symbolic schedule' do
        entry = Crontab::Entry.parse('@daily echo hello')
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
        entry.uid.should == Process.uid

        entry = Crontab::Entry.parse('0 0 * * * echo hello', false)
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
        entry.uid.should == Process.uid
      end

      it 'should parse system crontab entry line' do
        entry = Crontab::Entry.parse('0 0 * * * root echo hello', true)
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
        entry.uid.should == Etc.getpwnam('root').uid
      end

      it 'should parse system crontab entry line with symbolic schedule' do
        entry = Crontab::Entry.parse('@daily root echo hello', true)
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
        entry.uid.should == Etc.getpwnam('root').uid
      end

      it 'should ignore leading whitespaces' do
        entry = Crontab::Entry.parse('  @daily  echo hello')
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command

        entry = Crontab::Entry.parse('  0 0 * * *  echo hello')
        entry.schedule.from(@schedule.start).should == @schedule
        entry.command.should == @command
      end
    end
  end

  describe 'when accessing' do
    before :each do
      @schedule = Crontab::Schedule.new('@hourly')
      @other_schedule = Crontab::Schedule.new('@monthly')
      @command = 'ehco hello'
      @other_command = 'echo bonjour'
      @entry = Crontab::Entry.new(@schedule, @command)
    end

    it 'should be read-accessible to schedule' do
      @entry.schedule.should == @schedule
      lambda { @entry.schedule = @other_schedule }.should raise_error(NoMethodError)
      @entry.schedule.should == @schedule
    end

    it 'should freeze schedule' do
      @entry.schedule.should be_frozen
    end

    it 'should be read-accessible to command' do
      @entry.command.should == @command
      lambda { @entry.command = @other_command }.should raise_error(NoMethodError)
      @entry.command.should == @command
    end

    it 'should freeze command' do
      @entry.command.should be_frozen
    end

    it 'should be read-accessible to uid' do
      @entry.uid.should == Process.uid
      Process.uid.should_not == 0
      lambda { @entry.uid = 0 }.should raise_error(NoMethodError)
      @entry.uid.should == Process.uid
    end

    it 'should freeze uid' do
      pending 'Fixnum instances stay unfrozen'
      @entry.uid.should be_frozen
    end
  end
end
