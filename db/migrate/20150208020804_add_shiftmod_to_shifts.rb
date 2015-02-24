class AddShiftmodToShifts < ActiveRecord::Migration
  def change
    add_column :shifts, :shiftmod, :string, default: ""
  end
end
