require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'crontab/entry'
require 'crontab/schedule'

describe Crontab::Entry do
  describe 'when instantiating' do
    before :each do
      @cron_definition = '0 0 * * *'
      @schedule = Crontab::Schedule.new(@cron_definition) # @daily
      @command = 'echo hello'
    end

    it 'should accpet Crontab::Schedule and command String' do
      entry = Crontab::Entry.new(@schedule, @command, @cron_definition)
      entry.uid.should == Process.uid
    end

    it 'should accpet Crontab::Schedule, command String and user String' do
      uid = Process.uid
      user = Etc.getpwuid(uid)
      entry = Crontab::Entry.new(@schedule, @command, @cron_definition, user.name)
      entry.uid.should == uid
    end

    it 'should accpet Crontab::Schedule, command String and user ID' do
      uid = Process.uid
      entry = Crontab::Entry.new(@schedule, @command, @cron_definition, uid)
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
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command and
        entry.uid.should == Process.uid

        entry = Crontab::Entry.parse('0 0 * * * echo hello', :system => false)
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command and
        entry.uid.should == Process.uid
      end

      it 'should parse crontab entry line with symbolic schedule' do
        entry = Crontab::Entry.parse('@daily echo hello')
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command and
        entry.uid.should == Process.uid

        entry = Crontab::Entry.parse('0 0 * * * echo hello', :system => false)
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command and
        entry.uid.should == Process.uid
      end

      it 'should parse system crontab entry line' do
        entry = Crontab::Entry.parse('0 0 * * * root echo hello', :system => true)
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command and
        entry.uid.should == Etc.getpwnam('root').uid
      end

      it 'should parse system crontab entry line with symbolic schedule' do
        entry = Crontab::Entry.parse('@daily root echo hello', :system => true)
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command and
        entry.uid.should == Etc.getpwnam('root').uid
      end

      it 'should ignore leading whitespaces' do
        entry = Crontab::Entry.parse('  @daily  echo hello')
        entry.schedule.from(@schedule.start).should == @schedule and
        entry.command.should == @command

        entry = Crontab::Entry.parse('  0 0 * * *  echo hello')
        entry.schedule.from(@schedule.start).should == @schedule and
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
      @cron_definition = '0 0 * * *'
      @other_cron_definition = '0,30 0 * * *'
      @translation = ['midnight', 'every day']
      @other_translation = ['0 and 30 minutes past', 'midnight of', 'every day']
      @entry = Crontab::Entry.new(@schedule, @command, @cron_definition)
    end

    it 'should be read-accessible to schedule' do
      @entry.schedule.should == @schedule and
      lambda { @entry.schedule = @other_schedule }.should raise_error(NoMethodError)
      @entry.schedule.should == @schedule
    end

    it 'should freeze schedule' do
      @entry.schedule.should be_frozen
    end

    it 'should be read-accessible to command' do
      @entry.command.should == @command and
      lambda { @entry.command = @other_command }.should raise_error(NoMethodError)
      @entry.command.should == @command
    end

    it 'should freeze command' do
      @entry.command.should be_frozen
    end

    it 'should be read-accessible to uid' do
      @entry.uid.should == Process.uid and
      Process.uid.should_not == 0 and
      lambda { @entry.uid = 0 }.should raise_error(NoMethodError)
      @entry.uid.should == Process.uid
    end

    it 'should be freeze cron_definition' do
      @entry.cron_definition.should be_frozen
    end

    it 'should be read-accessible to cron_definition' do
      @entry.cron_definition == @cron_definition and
      lambda { @entry.cron_definition = @other_cron_definition }.should raise_error(NoMethodError)
      @entry.cron_definition == @cron_definition
    end

    it 'should be freeze translation' do
      @entry.translation.should be_frozen
    end

    it 'should be read-accessible to translation' do
      @entry.translation == @translation and
      lambda { @entry.translation = @other_translation }.should raise_error(NoMethodError)
      @entry.translation == @translation
    end
  end
end
