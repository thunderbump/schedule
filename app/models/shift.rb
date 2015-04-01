class Shift < ActiveRecord::Base
  belongs_to :person

  def time_in_shift?(time)
    (start < time) && (finish > time)
  end

  def to_s
    person.name + ": " + start.to_formatted_s(:long) + " - " + finish.to_formatted_s(:long) + " at " + location
  end
end
