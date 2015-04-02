class PeopleController < ApplicationController
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  # GET /people
  # GET /people.json
  def index
    @people = Person.all
  end

  # GET /people/1
  # GET /people/1.json
  def show
    @shifts = Person.find(params[:id]).shifts.order(start: :asc)
    #@weeks = build_shifts
    @days = Array.new

    day_idx = @shifts.first.start.at_beginning_of_day
    while day_idx < @shifts.last.finish
      @days.append(Day.new(day_idx, @shifts.select { |s| (s.start < day_idx.at_end_of_day) && (s.finish > day_idx) }))
      day_idx += 1.days
    end
  end

  # GET /people/new
  def new
    @person = Person.new
  end

  # GET /people/1/edit
  def edit
  end

  # POST /people
  # POST /people.json
  def create
    @person = Person.new(person_params)

    respond_to do |format|
      if @person.save
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
        format.json { render :show, status: :created, location: @person }
      else
        format.html { render :new }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /people/1
  # PATCH/PUT /people/1.json
  def update
    respond_to do |format|
      if @person.update(person_params)
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.json { render :show, status: :ok, location: @person }
      else
        format.html { render :edit }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person.destroy
    respond_to do |format|
      format.html { redirect_to people_url, notice: 'Person was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  SHIFT1 = 0
  SHIFT2 = 1
  OFF1 = 2
  ON1 = 3
  OFF2 = 4
  ON2 = 5
  OFF3 = 6
  DAY_SIZE = 7

  # Use callbacks to share common setup or constraints between actions.
  def set_person
    @person = Person.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def person_params
    params.require(:person).permit(:name)
  end
  

#  # day ary: [shift1, shift2, first off, first shift, second off, second shift, third off]
#  # start at the beginning and que up shifts. 
#  #
#  # working_weeks: [   week[   day[first_shift, second_shift, ....]]]
#  # assumed never more than 2 shifts per day, and shifts won't overlap.
#  def build_shifts
#    shifts = Person.find(params[:id]).shifts.order(start: :asc)
#    #Shifts that end on midnight are a boundry condition. remove them and the math works.
#    #put them back in at the very end
#    shifts.each do |shift|
#      if shift.finish == shift.finish.beginning_of_day
#        shift.finish -= 1.minutes
#      end
#    end
#    #init working_weeks
#    working_weeks = [[[shifts[0].dup]]]
#
#    shifts.each_with_index do |shift, idx|
#
#      #account for the init without checking for splitting days/months
#      if idx == 0 
#        if shift.start.strftime("%U") != shift.finish.strftime("%U") or
#           shift.start.wday != shift.finish.wday
#
#          working_weeks[0][0][0].finish = working_weeks[0][0][0].start.end_of_day
#          shift.start = shift.finish.beginning_of_day
#        else
#          next
#        end
#      end
#      #split days/months up if they occur during a shift
#      if shift.start.strftime("%U") != shift.finish.strftime("%U") or
#        shift.start.wday != shift.finish.wday
#
#        first_bit = shift.dup
#        first_bit.finish = first_bit.start.end_of_day
#        append_shift first_bit, working_weeks
#
#        shift.start = shift.finish.beginning_of_day
#        append_shift shift, working_weeks
#      else
#        append_shift(shift, working_weeks)
#      end
#
#    end
#
#    #build the colspan part of the array after the shift objects.
#    working_weeks.each do |week|
#      week.each do |day|
#        if day.length > 2
#          next
#        elsif day.length == 1
#          day.append nil
#        end
#
#        day.append day[0].start.hour * 2 + day[0].start.min / 30
#        day.append (day[0].finish.hour * 2 + (day[0].finish.min + 1) / 30) - 
#                   (day[0].start.hour * 2 + day[0].start.min / 30)
#        if day[1].nil?
#          day.append 48 - (day[0].finish.hour * 2 + (day[0].finish.min + 1) / 30)
#          2.times do
#            day.append 0
#          end
#        else 
#          day.append (day[1].start.hour * 2 + (day[1].start.min) / 30) -
#                     (day[0].finish.hour * 2 + (day[0].finish.min + 1) / 30)
#          day.append (day[1].finish.hour * 2 + (day[1].finish.min + 1) / 30) -
#                     (day[1].start.hour * 2 + day[1].start.min / 30)
#          day.append 48 - (day[1].finish.hour * 2 + (day[1].finish.min + 1) / 30)
#        end
#      end
#    end
#
#    #fix the boundry condition allowance made at the beginning.
#    shifts.each do |shift|
#      if shift.finish + 1.minutes == (shift.finish + 1.minutes).beginning_of_day
#        shift.finish += 1.minutes
#      end
#    end
#
#
#    return working_weeks
#  end

  #lots of repetition without this.
  def append_shift(shift, weeks)
    if shift.start.strftime("%U") != weeks[-1][-1][-1].start.strftime("%U")
      weeks.append [[shift]]
    elsif shift.start.wday != weeks[-1][-1][-1].start.wday
      weeks[-1].append [shift]
    else
      weeks[-1][-1].append shift
    end
  end
end
