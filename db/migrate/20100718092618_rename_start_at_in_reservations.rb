class RenameStartAtInReservations < ActiveRecord::Migration
  def self.up
    rename_column :reservations, :start_at, :starts_at
    rename_column :reservations, :end_at, :ends_at
  end

  def self.down
    rename_column :reservations, :ends_at, :end_at
    rename_column :reservations, :starts_at, :start_at
  end
end
