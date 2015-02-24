class UpdateController < ApplicationController

  def update
  end

  def parse
    parser = ShiftParser.new(params[:raw_schedule])
    errno = parser.test
    redirect_to update_path, notice: errno
  end
end
