class AddLocationToShifts < ActiveRecord::Migration
  def change
    add_column :shifts, :location, :string
  end
end
