class ShiftsController < ApplicationController
  before_action :set_shift, only: [:show, :edit, :update, :destroy]

  # GET /shifts
  # GET /shifts.json
  def index
    @shifts = Shift.all.sort_by { |s| s.start }
    @days = Array.new
    @names = Person.all.sort_by { |n| n.name }
    beginning = @shifts[0].start.at_beginning_of_day
    ending = @shifts[0].start.at_end_of_day
    while beginning <= @shifts.last.finish
      pre_colspans = Shift.where(['(start > ? AND start < ?) OR (finish > ? AND finish < ?)', beginning, ending, beginning, ending])
      day_prep = Array.new
      pre_colspans.each do |shift|
        before = shift.start < beginning ? 0 : shift.start.hour * 2 + shift.start.min / 30
        during_start = shift.start < beginning ? beginning : shift.start
        during_end = shift.finish > ending ? ending : shift.finish
        #subtracting datetimes results in difference in seconds. divide by 60 to get minutes then 30 
        #to get # half hours which is the size our table cells represent -> divide by 1800
        during = (during_end.to_time - during_start.to_time) / 1800
        after = shift.finish > ending ? 0 : (ending - shift.finish) / 1800
        day_prep.append([shift, before.round, during.round, after.round])
      end
      @days.append(day_prep)
      beginning += 1.days
      ending += 1.days
    end

  end

  # GET /shifts/1
  # GET /shifts/1.json
  def show
  end

  # GET /shifts/new
  def new
    @shift = Shift.new
  end

  # GET /shifts/1/edit
  def edit
  end

  # POST /shifts
  # POST /shifts.json
  def create
    @shift = Shift.new(shift_params)

    respond_to do |format|
      if @shift.save
        format.html { redirect_to @shift, notice: 'Shift was successfully created.' }
        format.json { render :show, status: :created, location: @shift }
      else
        format.html { render :new }
        format.json { render json: @shift.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shifts/1
  # PATCH/PUT /shifts/1.json
  def update
    respond_to do |format|
      if @shift.update(shift_params)
        format.html { redirect_to @shift, notice: 'Shift was successfully updated.' }
        format.json { render :show, status: :ok, location: @shift }
      else
        format.html { render :edit }
        format.json { render json: @shift.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shifts/1
  # DELETE /shifts/1.json
  def destroy
    @shift.destroy
    respond_to do |format|
      format.html { redirect_to shifts_url, notice: 'Shift was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shift
      @shift = Shift.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shift_params
      params.require(:shift).permit(:start, :end, :person_id, :location)
    end
end
