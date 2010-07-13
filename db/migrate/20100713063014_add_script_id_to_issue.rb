class AddScriptIdToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :experiment_script_id, :integer
  end

  def self.down
    remove_column :issues, :experiment_script_id
  end
end
