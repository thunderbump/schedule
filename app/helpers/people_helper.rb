module PeopleHelper
  def get_class(idx, day)
    matches = day.select { |s| s.time_in_shift?(day.get_date + (30 * idx).minutes) }
    if matches.size == 0
      return "schedule_off"
    elsif matches.size == 1
      return matches.first.location + " " + (["VAC", "PER", "SIK", "SICK"].include?(matches.first.shiftmod) ? "inactive" : "")
    else
      #placeholder. needs to show conflicts between active shifts and ignore inactive 
      #when there's a competing active shift.
      return matches.first.location
    end
  end

end
