class Shift < ActiveRecord::Base
  belongs_to :person

  def to_s
    person.name + ": " + start.to_formatted_s(:long) + " - " + finish.to_formatted_s(:long) + " at " + location
  end
end
