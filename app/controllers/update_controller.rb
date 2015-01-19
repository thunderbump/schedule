class UpdateController < ApplicationController
  def update
  end

  def parse
    errno = parse_exec params[:raw_schedule]
    redirect_to update_path, notice: errno
  end

  private
  #raw_ary: split raw_sched by \n
  #A: header at 0. includes location and month/year
  #B: week headers at 1. includes day. discard as datetime handles this
  #C: date headers at 14n + 2(n in [0-5]). use first date to initialize line counters
  #D: all other lines are potential shifts
  #
  #ln_ary: split raw_ary lines by \t
  #location in A[0]
  #Year in A[0]
  #Month in A[0]
  #Date initializers in C[3n]
  #Shift Name in D[3n] n in [0-6]
  #Shift Start in D[3n+1] n in [0-6]
  #Shift End in D[3n+1] n in [0-6]
  JANUARY = 1
  DECEMBER = 12

  HEADER = 0
  #  WEEK_HEADER = 1
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
  SHIFT_FIELDS = 3
  MAX_SHIFT_COLS = 7
  SHIFT_ROWS = 14
  DATE_CHECK_INIT = 1
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
    name_ary = Array.new
    shift_ary = Array.new
    #Step through the dates and pick out people and shifts
    (parse_ary.length / SHIFT_FIELDS).times do |index|
      #strip out this index's date
      shift_date = parse_ary[HEADER][index * SHIFT_FIELDS].split('-')[DATE_BLK].to_i
      shift_month = month
      #if we're not in the current month
      if shift_date != date_check
        #date_check not set so still before the current month.
        if date_check == DATE_CHECK_INIT
          shift_month = JANUARY ? DECEMBER : month + 1
        #date_check set so after
        else
          shift_month = DECEMBER ? JANUARY : month + 1
        end
      #otherwise we're in this month. Prep it for the next iteration
      else
        date_check += 1
      end

      parse_ary.last(SHIFT_ROWS - 1).each do |line|
        name = line[index * SHIFT_FIELDS + NAME_BLK]
        start, finish = line[index * SHIFT_FIELDS + TIME_BLK].split('-')
        unless name_ary.include? name
          name_ary.append name
        end
        shift_ary.append [name_ary.index, start, finish]
      end
    end

#    return location.inspect + ' ' + month.inspect + ' ' + year.inspect + ' ' + name_ary.inspect
    return parse_ary.inspect
  end
end
