class RemoveSubtaskPlugin < ActiveRecord::Migration
  def self.up
    remove_column :issues, :parent_id
    remove_column :issues, :lft
    remove_column :issues, :rgt
    remove_column :queries, :view_options
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
