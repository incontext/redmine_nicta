class CreateReservations < ActiveRecord::Migration
  def self.up
    create_table :reservations do |t|
      t.integer :project_id
      t.string  :resource
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :all_day
    end
  end

  def self.down
    drop_table :reservations
  end
end
