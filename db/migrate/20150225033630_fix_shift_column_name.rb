class FixShiftColumnName < ActiveRecord::Migration
  def change
    rename_column :shifts, :end, :finish
  end
end
