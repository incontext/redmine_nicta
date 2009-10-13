class InitTrackersAndCustomFields < ActiveRecord::Migration
  def self.up
    Issue.destroy_all
    Tracker.destroy_all
    script_tracker = Tracker.create!(:name => 'Script', :is_in_chlog => true, :is_in_roadmap => true)
    script_run_tracker = Tracker.create!(:name => 'Script run', :is_in_chlog => true, :is_in_roadmap => true)

    IssueCustomField.destroy_all
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
    IssueCustomField.create!(:name => 'Run start time', :field_format => 'date', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Run duration', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Attribute text', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Log file', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Run results', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
  end

  def self.down
  end
end
