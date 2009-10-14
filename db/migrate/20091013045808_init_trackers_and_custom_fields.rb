class InitTrackersAndCustomFields < ActiveRecord::Migration
  def self.up
    Issue.destroy_all('parent_id is null')
    Tracker.destroy_all
    script_tracker = Tracker.create!(:name => 'Script', :is_in_chlog => true, :is_in_roadmap => true)
    script_run_tracker = Tracker.create!(:name => 'Script run', :is_in_chlog => true, :is_in_roadmap => true)

    CustomField.destroy_all
    #Script
    IssueCustomField.create!(:name => 'Type', :field_format => 'list', :possible_values => ['Wifi', 'Ethernet', '3G', 'DSRC'],
                             :is_required => true, :is_for_all => true, :is_filter => true).trackers << script_tracker
    IssueCustomField.create!(:name => 'Batch', :field_format => 'bool',
                             :is_required => true, :is_for_all => true, :is_filter => true).trackers << script_tracker
    IssueCustomField.create!(:name => 'Resume', :field_format => 'bool',
                             :is_required => true, :is_for_all => true, :is_filter => true).trackers << script_tracker

    #Script run
    IssueCustomField.create!(:name => 'Script version', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Script uri', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Run start time', :field_format => 'string', :regexp =>  "^((([0]?[1-9]|1[0-2])(:|\.)[0-5][0-9]((:|\.)[0-5][0-9])?( )?(AM|am|aM|Am|PM|pm|pM|Pm))|(([0]?[0-9]|1[0-9]|2[0-3])(:|\.)[0-5][0-9]((:|\.)[0-5][0-9])?))$", :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Run duration', :field_format => 'string', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Attribute text', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Log file', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Log data', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Measurements DB', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Measurements metadata', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
  end

  def self.down
  end
end
