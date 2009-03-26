require File.join(File.dirname(__FILE__), 'spec_helper')
require 'crontab'

describe Crontab do
  describe 'parsing' do
    it 'should recognize entries' do
      crontab = Crontab.parse(File.read('spec/data/crontab.txt'))
      crontab.entries.size.should == 5
      crontab.entries.should be_frozen
      crontab.entries[0].tap do |e|
        e.schedule.minutes.should == [8]
        e.schedule.hours.should == [3]
        e.schedule.day_of_months.should == (1..31).to_a
        e.schedule.months.should == (1..12).to_a
        e.schedule.day_of_weeks.should == [6]
      end
    end

    it 'should recognize variables assignments' do
      crontab = Crontab.parse(File.read('spec/data/crontab.txt'))
      crontab.env.should == {
        'SHELL' => '/bin/zsh',
        'MAIL_TO' => 'nobody@example.com',
        'FOO' => 'foo',
        'BAR' => 'bar',
        'BAZ' => 'baz'
      }
    end
  end
end
# 8 3 * * 6 run-parts $HOME/.cron.d/weekly
# 50 2 * * * run-parts $HOME/.cron.d/daily
# 3 * * * * run-parts $HOME/.cron.d/hourly
# 
# */5 * * * * curl -sI http://example.com >/dev/null
# 
# * * * * * awk 'BEGIN{ srand(); exit(rand() * 24 * 60.0 < 12.0 ? 0 : 1); }' && fortune
