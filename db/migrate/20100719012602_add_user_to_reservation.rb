class AddUserToReservation < ActiveRecord::Migration
  def self.up
    add_column :reservations, :user_id, :integer
    remove_column :reservations, :all_day
  end

  def self.down
    add_column :reservations, :all_day, :boolean
    remove_column :reservations, :user_id
  end
end
