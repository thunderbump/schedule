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
  def parse_exec(raw_sched)
    raw_ary = raw_sched.split("\n")
    location = ""
    year, month, date_init = 0
    raw_ary.each_with_index do |line, index|
      #idx 0 you're only working with the first block so split by ' ' instead of \t
      if index == 0
        ln_ary = line.split(' ')
        location = ln_ary[0]
        month = Date::MONTHNAMES.index(ln_ary[1])
        year = ln_ary[2].to_i
        next
      end
      ln_ary = line.split('\t')
      #see if it's a date line and make sure it's not using anything from last month
      #treat the first differently to reflect this
      #date_init will be the first date of the line and be used to incriment later.
      if index == 2
        ln_ary.each_with_index do |block, blk_idx|
          if blk_idx % 3 == 0
            if block.split('-').first.to_i == 1
              date_init = blk_idx / 3 + 1
            end
          end
        end
      #if it's not the first then just take the first in the array and pull the date
      elsif (index - 2) % 14 == 0
        #----------------------------------------------------
        #this is including the last line if it starts on a different month. This should be checked for and
        #excluded
        #----------------------------------------------------
        date_init = ln_ary.first.split('-').first.to_i
      end
    end
    sched = raw_sched.gsub("\t", "!t").gsub("\n", "!B!")
    return location.inspect + ' ' + month.inspect + ' ' + year.inspect + ' ' + date_init.inspect
  end
end
