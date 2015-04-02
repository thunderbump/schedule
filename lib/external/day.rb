require 'forwardable'

class Day
  include Enumerable
  extend Forwardable
  def_delegators :@shifts, :each, :<<, :all, :map, :select

  def initialize(date_init, shift_list)
    @date = date_init
    @shifts = shift_list
  end

#  def each(&block)
#    @shifts.each(&block)
#  end
  
  def get_date
    @date
  end
end
