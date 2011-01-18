class AddReservationOptionToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :reservation_option, :string
  end

  def self.down
    remove_column :issues, :reservation_option
  end
end
