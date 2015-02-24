class ShiftParser

  #old defaults
  JANUARY = 1
  DECEMBER = 12

  HEADER = 0
  DATE_HEADER_INITIAL = 1
  DATE_HEADER_MOD = 14
  RAW_DATE_HEADER_OFFSET = 2
  DATE_HEADER_OFFSET = 1
  PARSE_HEADER = 0

  LOCATION_BLK = 0
  MONTH_BLK = 1
  YEAR_BLK = 2
  DATE_BLK = 0
  DATE_BLK_MOD = 3
  NAME_BLK = 0
  TIME_BLK = 1
  TYPE_BLK = 2
  SHIFT_FIELDS = 3
  MAX_SHIFT_COLS = 7
  SHIFT_ROWS = 14
  DATE_CHECK_INIT = 1
  COMBINED_SHIFT_COLS = 42

  #new defaults
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

  #new_parse
  def initialize(raw_sched)
    @raw_text = raw_sched
    parse
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
      
      start = DateTime.new(@authoritative_year, @authoritative_month, numeric_day, start_h, start_m, 0)
      finish = DateTime.new(@authoritative_year, @authoritative_month, numeric_day, finish_h, finish_m, 0)

      if start > finish
        finish += 1.days
      end

      shifts.append Shift.new(person: person, location: @facility, start: start, end: finish, shiftmod: mod)
      shifts[-1].save
    end
    return shifts
  end

  def clean_month
    start = DateTime.new(@authoritative_year, @authoritative_month, 1).beginning_of_month
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

   def segment_h_m(time)
     return [time[HOUR_START, HOUR_END].to_i, time[MIN_START, MIN_END].to_i]
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
    header[FACILITY]
  end

  def find_authoritative_month(header)
    Date::MONTHNAMES.index(header[AUTHORITATIVE_MONTH])
  end

  def find_authoritative_year(header)
    header[AUTHORITATIVE_YEAR].to_i
  end
  #old parse
  def parse_exec(raw_sched)
    raw_ary = raw_sched.split("\n")
    date_check = DATE_CHECK_INIT
    date_offset = 0

    #Parse the header
    header_ary = raw_ary[HEADER].split(' ')
    location = header_ary[LOCATION_BLK]
    month = Date::MONTHNAMES.index(header_ary[MONTH_BLK])
    year = header_ary[YEAR_BLK].to_i

    #now line up the weeks end-to-end to get it out of excell's stupid formatting
    parse_ary = Array.new(DATE_HEADER_MOD) {Array.new}
    raw_ary.each_with_index do |line, index|
      line_ary = line.split("\t")
      if index < RAW_DATE_HEADER_OFFSET
        next
      elsif (index - RAW_DATE_HEADER_OFFSET) % DATE_HEADER_MOD == PARSE_HEADER
        parse_ary[PARSE_HEADER].concat line_ary[0, SHIFT_FIELDS * MAX_SHIFT_COLS]
      else
        parse_ary[(index - RAW_DATE_HEADER_OFFSET) % DATE_HEADER_MOD].concat line_ary[0, SHIFT_FIELDS * MAX_SHIFT_COLS]
      end
    end

    name_ary = Person.all
    Shift.delete_all(['location = ? AND start > ? AND start < ?', location, 
                      DateTime.strptime(parse_ary[0][0], "%e-%b"),
                      DateTime.strptime(parse_ary[0][-3], "%e-%b").end_of_day])
    shift_ary = Array.new
    #Step through the dates and pick out people and shifts
    COMBINED_SHIFT_COLS.times do |index|
      #strip out this index's date
      shift_day = parse_ary[HEADER][index * SHIFT_FIELDS].split('-')[DATE_BLK].to_i
      shift_month = month
      shift_year = year
      #if we're not in the current month
      if shift_day != date_check
        #date_check not set so still before the current month.
        if date_check == DATE_CHECK_INIT
          if shift_month == JANUARY
            shift_month = DECEMBER
            shift_year -= 1
          else
            shift_month = month - 1
          end
          #date_check set so after
        else
          if shift_month == DECEMBER
            shift_month = JANUARY
            shift_year += 1
          else
            shift_month = month + 1
          end
        end
        #otherwise we're in this month. Prep it for the next iteration
      else
        date_check += 1
      end

      parse_ary.last(SHIFT_ROWS - 1).each do |line|
        name = line[index * SHIFT_FIELDS + NAME_BLK]
        if name == "" or name == nil
          next
        end
        #byebug
        start_time, end_time = line[index * SHIFT_FIELDS + TIME_BLK].split('-')
        shift_type = line[index * SHIFT_FIELDS + TYPE_BLK]
        unless name_ary.find { |n| n.name == name }
          person = Person.new(name: name)
          person.save
          name_ary.append person

        end
        #unless name_ary.include? name
        #  name_ary.append name
        #end
        start = DateTime.new(shift_year, shift_month, shift_day, start_time[0,2].to_i, start_time[2,4].to_i, 0)
        if start_time > end_time
          #byebug
          delta = end_time.to_i - start_time.to_i + 2400
          end_datetime = start + (delta / 100).hours + (delta % 100).minutes
        else
          end_datetime = DateTime.new(shift_year, shift_month, shift_day, end_time[0,2].to_i, end_time[2,4].to_i, 0)
        end
        shift = Shift.new(person: name_ary.find { |n| n.name == name }, location: location, start: start, end: end_datetime, shiftmod: shift_type)
        shift.save
        shift_ary.append shift
        #shift_ary.append [name, name_ary.find { |n| n.name == name }, start, end_datetime]
        #shift_ary.append [name, name_ary.index(name), start, end_datetime]

      end
    end

    #    return location.inspect + ' ' + month.inspect + ' ' + year.inspect + ' ' + name_ary.inspect
    return shift_ary.inspect + " " + shift_ary.length.to_s
  end
end
