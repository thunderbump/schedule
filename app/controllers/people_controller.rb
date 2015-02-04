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
    @weeks = build_shifts
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

  # day ary: [shift1, shift2, first off, first shift, second off, second shift, third off]
  # start at the beginning and que up shifts. 
  #
  # working_weeks: [   week[   day[first_shift, second_shift, ....]]]
  # assumed never more than 2 shifts per day, and shifts won't overlap.
  def build_shifts
    shifts = Person.find(params[:id]).shifts.order(start: :asc)
    #Shifts that end on midnight are a boundry condition. remove them and the math works.
    #put them back in at the very end
    shifts.each do |shift|
      if shift.end == shift.end.beginning_of_day
        shift.end -= 1.minutes
      end
    end
    #init working_weeks
    working_weeks = [[[shifts[0]]]]
    if shifts[0].start.strftime("%U").to_i != shifts[0].end.strftime("%U").to_i or
      shifts[0].start.wday != shifts[0].end.wday
      #check for which it is because you have to append different things to different places.
      if shifts[0].start.strftime("%U").to_i != shifts[0].end.strftime("%U").to_i
        #duplicate the current shift and add it
        working_weeks.append [[shifts[0].dup]]
        #then set the dup's start and the original's end so you know what day it is later.
        working_weeks[0][0][0].end = working_weeks[0][0][0].start.end_of_day
        working_weeks[-1][-1][-1].start = working_weeks[-1][-1][-1].end.beginning_of_day
      elsif shifts[0].start.wday != shifts[0].end.wday
        working_weeks[0].append [shifts[0].dup]
        working_weeks[0][0][0].end = working_weeks[0][0][0].start.end_of_day
        working_weeks[-1][-1][-1].start = working_weeks[-1][-1][-1].end.beginning_of_day
      end
    end



    shifts.each_with_index do |shift, idx|
      if idx == 0 
        next
      end

      if shift.start.strftime("%U") != shift.end.strftime("%U") or
        shift.start.wday != shift.end.wday

        first_bit = shift.dup
        first_bit.end = first_bit.start.end_of_day
        append_shift first_bit, working_weeks

        shift.start = shift.end.beginning_of_day
        append_shift shift, working_weeks
      else
        append_shift(shift, working_weeks)
      end

    end

    working_weeks.each do |week|
      week.each do |day|
        if day.length > 2
          next
        elsif day.length == 1
          day.append nil
        end

        day.append day[0].start.hour * 2 + day[0].start.min / 30
        day.append (day[0].end.hour * 2 + (day[0].end.min + 1) / 30) - 
                   (day[0].start.hour * 2 + day[0].start.min / 30)
        if day[1].nil?
          day.append 48 - (day[0].end.hour * 2 + (day[0].end.min + 1) / 30)
          2.times do
            day.append 0
          end
        else 
          day.append (day[1].start.hour * 2 + (day[1].start.min) / 30) -
                     (day[0].end.hour * 2 + (day[0].end.min + 1) / 30)
          day.append (day[1].end.hour * 2 + (day[1].end.min + 1) / 30) -
                     (day[1].start.hour * 2 + day[1].start.min / 30)
          day.append 48 - (day[1].end.hour * 2 + (day[1].end.min + 1) / 30)
        end
      end
    end

    shifts.each do |shift|
      if shift.end + 1.minutes == (shift.end + 1.minutes).beginning_of_day
        shift.end += 1.minutes
      end
    end


    return working_weeks
  end

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
