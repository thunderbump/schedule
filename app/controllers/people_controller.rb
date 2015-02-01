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
    def build_shifts
      #group by weeks, then by days, then see how many shifts there are. Setup weeks and day arrays
      weeks = []
      weeks.append []
      current_day = [DAY_SIZE]
      #grab all the shifts for this ID
      shifts = Person.find(params[:id]).shifts.order(start: :asc)
      #init the day array.
      current_day[SHIFT1] = shifts[0]
      current_day[OFF1] = shifts[0].start.hour * 2 + shifts[0].start.min / 30
      #first off is always the same. get that set then look at if shift is split by the end of day
      if shifts[0].start.wday != shifts[0].end.wday
        #If it is just fill in the rest of the day and zero out everything else left.
        current_day[ON1] = 24 * 2 - (shifts[0].start.hour * 2 + shifts[0].start.min / 30)
        current_day[OFF2] = current_day[ON2] = current_day[OFF3] = 0
        #that day's done get it on the week array
        weeks[0].append current_day
        #and get a new day up
        current_day = [DAY_SIZE]
        current_day[SHIFT1] = shifts[0]
        #no offtime before because it's split overnight
        current_day[OFF1] = 0
        current_day[ON1] = shifts[0].end.hour * 2 + shifts[0].end.min / 30
      else
        current_day[ON1] = (shifts[0].end.hour * 2 + shifts[0].end.min / 30) - 
                         (shifts[0].start.hour * 2 + shifts[0].start.min / 30)
      end
      #
      #
      #Forgot to check for new weeks...can probably just do that with the current day increment.
      #How would i keep from repeating so much here without making a mess of it?
      #
      #
      #Day arrays will always leave the next shift with the first unused offtime not filled in.
      #shift1 must be set -- cleanup will happen at the beginning of the next shift or at the end, even
      # if you've already encountered 2 shifts this day.
      #it's assumed you won't encounter more than 2 shifts a day.
      shifts.drop(1).each do |shift|
        #Check for if you're cleaning up the last shift
        if current_day[SHIFT2] or current_day[SHIFT1].end.wday != shift.beginning.wday
          if current_day[SHIFT2]
            current_day[OFF3] = 24 * 2 - (current_day[SHIFT2].end.hour * 2 + 
                                          current_day[SHIFT2].end.min / 30)
          else
            current_day[OFF2] = 24 * 2 - (current_day[SHIFT1].end.hour * 2 +
                                          current_day[SHIFT1].end.min / 30)
            current_day[ON2] = current_day[OFF3] = 0
          end
          weeks.append current_day
          current_day = [DAY_SIZE]
          #This should be the only point you're setting SHIFT1 except in day overflow
          #(then it gets set in set_shift)
          current_day[SHIFT1] = shift

        end
      end
      return weeks
    end
      
    def set_shift
    end
end
