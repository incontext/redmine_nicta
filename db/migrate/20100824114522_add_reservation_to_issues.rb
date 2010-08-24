class AddReservationToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :reservation_id, :integer
  end

  def self.down
    remove_column :issues, :reservation_id
  end
end
