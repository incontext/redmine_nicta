class MoveScriptUrlToScript < ActiveRecord::Migration
  def self.up
    script_run_tracker = Tracker.find_by_name('Script run')
    script_uri_custom_field = IssueCustomField.find_by_name('Script uri')
    script_uri_custom_field.trackers.delete(script_run_tracker)
    script_uri_custom_field.destroy
    add_column :issues, :script_path, :string
  end

  def self.down
    script_run_tracker = Tracker.find_by_name('Script run')
    IssueCustomField.create!(:name => 'Script uri', :field_format => 'text', :is_for_all => true, :searchable => true).trackers << script_run_tracker
    remove_column :issues, :script_path
  end
end
