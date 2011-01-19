class AddExperimentLibrariesToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :libraries, :text
  end

  def self.down
    remove_column :issues, :libraries
  end
end
