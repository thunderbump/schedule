class DowncaseLocationInShifts < ActiveRecord::Migration
  def change
    Shift.all.each do |shift|
      shift.update_attributes :location => shift.location.downcase
    end
  end
end
