class MoveCustomFieldsToIssueAttributes < ActiveRecord::Migration
  def self.up
    script_run_tracker = Tracker.find_by_name('Script run')
    script_run_custom_fields = IssueCustomField.find(:all, :conditions => { :name => ['Script version', 'Attribute text', 'Log data']})
    script_run_custom_fields.each do |v|
      v.trackers.delete(script_run_tracker)
      v.destroy
    end

    add_column :issues, :script_version, :string
    add_column :issues, :attribute_text, :text
    add_column :issues, :log_data, :text
  end

  def self.down
    remove_column :issues, :log_data
    remove_column :issues, :attribute_text
    remove_column :issues, :script_version

    script_run_tracker = Tracker.find_by_name('Script run')

    IssueCustomField.create!(:name => 'Attribute text', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Script version', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    IssueCustomField.create!(:name => 'Log data', :field_format => 'text', :is_for_all => true).trackers << script_run_tracker
  end
end
