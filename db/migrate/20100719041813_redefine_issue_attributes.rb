class RedefineIssueAttributes < ActiveRecord::Migration
  def self.up
    rename_column :issues, :attribute_text, :experiment_attributes
    rename_column :issues, :experiment_script_id, :experiment_id
    rename_column :issues, :script_version, :experiment_version
  end

  def self.down
    rename_column :issues, :experiment_version, :script_version
    rename_column :issues, :experiment_id, :experiment_script_id
    rename_column :issues, :experiment_attributes, :attribute_text
  end
end
