class AddIdentifierToScript < ActiveRecord::Migration
  def self.up
    add_column :issues, :identifier, :string, :null => false
  end

  def self.down
    remove_column :issues, :identifier
  end
end
