class ShiftParser
  
  CELL_TEXT = 0

  #Header offsets
  DOC_HEADER = 0
  DOC_HEADER_END = 2
  FACILITY = 0
  AUTHORITATIVE_MONTH = 1
  AUTHORITATIVE_YEAR = 2

  #body to day offsets
  LINES_IN_DOC = 6
  DAYS_IN_LINE = 7
  DAY_WIDTH = 3
  DAY_HEIGHT = 14

  #Day offsets
  DAY_HEADER = 0
  DAY_HEADER_DATA = 0
  DAY_HEADER_DATE = 0
  DAY_HEADER_MONTH = 1
  DAY_HEADER_END = 1

  #Shift offsets
  SHIFT_NAME = 0
  SHIFT_TIMES = 1
  SHIFT_MOD = 2
  SHIFT_START = 0
  SHIFT_END = 1
  HOUR_START = 0
  HOUR_END = 2
  MIN_START = 2
  MIN_END = 4
  TIME_SIZE = 4
  SHORTENED_TIME_SIZE = 3

  #time stuff
  TIMEZONE = "Pacific Time (US & Canada)"

  #new_parse
  def initialize(raw_sched)
    @raw_text = raw_sched
    parse
  end

  def to_s
    shifts = ""
    @shifts.each do |shift|
      shifts << "#{shift.to_s}\n"
    end
    return shifts
  end

  def test
#    return @segmented_doc.inspect
#    return @facility.inspect
#    return @authoritative_year.inspect
    return @shifts
  end

  private
  #main parse function
  def parse
    @segmented_doc = segment_doc @raw_text
    segmented_doc = segment_doc @raw_text
    header = segmented_doc[DOC_HEADER]
    body = segmented_doc.drop(DOC_HEADER_END)

    @people = Person.all

    @facility = find_facility header
    @authoritative_month = find_authoritative_month header
    @authoritative_year = find_authoritative_year header

    clean_month

    @shifts = get_shifts body
  end

  def get_days(body)
    days = []
    LINES_IN_DOC.times do |line_n|
      week = body[line_n * DAY_HEIGHT..(line_n + 1) * DAY_HEIGHT - 1]
      DAYS_IN_LINE.times do |day_n|
        day = []
        week.each do |week_line|
          day.append week_line[day_n * DAY_WIDTH..(day_n + 1) * DAY_WIDTH - 1]
        end
        days.append day
      end
    end
    return days
  end

  def get_shifts(body)
    shifts = []
    days = get_days body
    days.each do |day|
      month = find_month_in_day(day)
      unless month == @authoritative_month
        next
      end
      
      shifts.concat get_shifts_from_day(day)
    end
    return shifts
  end

  def get_shifts_from_day(day)
    shifts = []
    numeric_day = find_date_in_day(day)
    day.drop(DAY_HEADER_END).each do |shift|
      if shift == nil or shift == []
        next
      end
      if shift[SHIFT_NAME] == ""
        next
      end

      person = find_person(shift[SHIFT_NAME])    
  
      start_t, finish_t = segment_shift_times(shift[SHIFT_TIMES])
      mod = shift[SHIFT_MOD]

      start_h, start_m = segment_h_m(start_t)
      finish_h, finish_m = segment_h_m(finish_t)
      #byebug
      Time.zone = TIMEZONE
      start = Time.zone.local(@authoritative_year, @authoritative_month, numeric_day, start_h, start_m, 0)
      finish = Time.zone.local(@authoritative_year, @authoritative_month, numeric_day, finish_h, finish_m, 0)

      if start > finish
        finish += 1.days
      end

      shifts.append Shift.new(person: person, location: @facility, start: start, finish: finish, shiftmod: mod)
      shifts[-1].save
    end
    return shifts
  end

  def clean_month
    start = Time.zone.local(@authoritative_year, @authoritative_month, 1).beginning_of_month
    finish = start.end_of_month
    Shift.delete_all(['location = ? AND start > ? AND start < ?', @facility, start, finish])
  end

  
  ####################################################################################
  #Segmentations
  #
  #Break up raw text into easier to parse chunks
  ####################################################################################
  

  #break up the doc into arrays
  def segment_doc(raw_sched)
    segmented_doc = []
    segment_rows(raw_sched).each do |row|
      segmented_doc.append segment_cols(row)
    end
    segmented_doc[DOC_HEADER] = segment_header segmented_doc[DOC_HEADER][CELL_TEXT]
    return segmented_doc
  end

  #helps segment_doc break up the raw doc into rows
  def segment_rows(sched)
    sched.split("\r\n")
  end

  #helps segment_doc break up columns within rows
  def segment_cols(sched)
    sched.split("\t")
  end

  #helps segment_doc break up the header
  def segment_header(header)
    header.split(" ")
  end

  def segment_day_header(header)
    header.split("-")
  end

  def segment_shift_times(times)
    times.split("-")
  end

  #Redo this at some point...
  def segment_h_m(time)
    if time.size == TIME_SIZE
      return [time[HOUR_START, HOUR_END].to_i, time[MIN_START, MIN_END].to_i]
    elsif time.size == SHORTENED_TIME_SIZE
      return [time[HOUR_START].to_i, time[MIN_START - 1, MIN_END - 1].to_i]
    else
      raise EncodingError
    end
  end
  
  ####################################################################################
  #Finds
  #
  #Pick out elements from a given array
  ####################################################################################
  
  def find_person(name)
    unless @people.find { |n| n.name == name }
      person = Person.new(name: name)
      person.save
      @people.append person
    end

    @people.find { |n| n.name == name }
  end

  def find_date_in_day(day)
    segment_day_header(day[DAY_HEADER][DAY_HEADER_DATA])[DAY_HEADER_DATE].to_i
  end

  def find_month_in_day(day)
    Date::ABBR_MONTHNAMES.index(segment_day_header(day[DAY_HEADER][DAY_HEADER_DATA])[DAY_HEADER_MONTH])
  end

  #returns the facility this schedule's for
  def find_facility(header)
    header[FACILITY].downcase
  end

  def find_authoritative_month(header)
    Date::MONTHNAMES.index(header[AUTHORITATIVE_MONTH])
  end

  def find_authoritative_year(header)
    header[AUTHORITATIVE_YEAR].to_i
  end
end
