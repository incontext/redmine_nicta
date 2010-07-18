class AddProjectIdToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :project_id, :integer
    add_column :experiments, :user_id, :integer
  end

  def self.down
    remove_column :experiments, :user_id
    remove_column :experiments, :project_id
  end
end
