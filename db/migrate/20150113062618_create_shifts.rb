class CreateShifts < ActiveRecord::Migration
  def change
    create_table :shifts do |t|
      t.datetime :start
      t.datetime :end
      t.belongs_to :person, index: true

      t.timestamps
    end
  end
end
