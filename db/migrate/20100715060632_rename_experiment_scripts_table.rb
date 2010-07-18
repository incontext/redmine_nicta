class RenameExperimentScriptsTable < ActiveRecord::Migration
  def self.up
    rename_table :experiment_scripts, :experiments

    remove_column :experiments, :script_file_name
    remove_column :experiments, :script_updated_at
    add_column :experiments, :identifier, :string
    add_column :experiments, :experiment_type, :string
  end

  def self.down
    remove_column :experiments, :experiment_type
    remove_column :experiments, :identifier
    add_column :experiments, :script_updated_at
    add_column :experiments, :script_file_name

    rename_table :experiments, :experiment_scripts
  end
end
