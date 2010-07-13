class CreateExperimentScripts < ActiveRecord::Migration
  def self.up
    create_table :experiment_scripts do |t|
      t.string :script_file_name
      t.datetime :script_updated_at
    end
  end

  def self.down
    drop_table :experiment_scripts
  end
end
