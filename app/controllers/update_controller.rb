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
  #Date initializers in C[0]
  #Shift Name in D[3n-1] n in [0-6]
  #Shift Start in D[3n] n in [0-6]
  #Shift End in D[3n] n in [0-6]
  def parse_exec(raw_sched)
    raw_ary = raw_sched.split("\n")
    sched = raw_sched.gsub("\t", "!t").gsub("\n", "!B!")
    return raw_ary[17].gsub("\t", "!t")
  end
end
