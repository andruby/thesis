# The assignment class holds an unsorted list of flights
# And sorted fleet classes
class Assignment
  attr_accessor :fleets, :flights, :available_craft
  cattr_accessor :params
  
  # Calculation parameters
  DEFAULT_PARAMS = {
    :rotation => 30.minutes,
    :fixed_cost_100 => 21,
    :var_cost_100 => 0.56,
    :price_short => 100,
    :price_medium => 200
  }
  
  def set_params(params)
    @@params ||= {}
    @@params.merge!(params)
  end
  
  def flight_with_id(id)
    @flights.find {|f| f.id == id }
  end
  
  class NoRoomForFlight < Exception; end;
  
  def initialize(flights,available_craft=nil)
    # set available craft to all craft if it is null
    @available_craft = (available_craft || AircraftType.find(:all, :conditions => ["count > 0"], :order => "id"))
    @flights = flights
    @fleets = ActiveSupport::OrderedHash.new
    @available_craft.each do |craft|
      @fleets[craft.ba_code] = Fleet.new(craft.ba_code,craft.count) unless craft.count < 1
    end
    
    # set default parameters
    self.set_params(DEFAULT_PARAMS)
  end
  
  def fit_flight(flight,surpress_errors=false)
    ba_code = flight.aircraft.ba_code
    fit = @fleets[ba_code].fit_flight(flight,@@params[:rotation])
    raise NoRoomForFlight, "No room for flight #{flight}" if fit == false && surpress_errors != true
    return true
  end
  
  def schedule!(surpress_errors=false)
    # clear previous schedules
    @fleets.each_value { |fleet| fleet.clear_schedules! }
    # reschedule
    @flights.each { |flight| self.fit_flight(flight,surpress_errors) }  
  end
  
  # bereken de omzet,kosten en winst
  def results
    # zet alle stats op 0
    omzet, fixed_cost, var_cost = 0, 0, 0
    # om makkelijker toegankelijk te maken hieronder
    price = {"Short" => @@params[:price_short], "Medium" => @@params[:price_medium]}
    spill = {"Short" => 0, "Medium" => 0}

    @flights.each do |f|
      [f.demand_1,f.demand_2].each do |demand|
        if f.capacity >= demand
          # de vraag wordt voldaan
          omzet += price[f.haul] * demand
        else
          # er is spill
          omzet += price[f.haul] * f.capacity
          spill[f.haul] += demand - f.capacity
        end
      end
      # Kosten toevoegen
      fixed_cost += 2 * f.aircraft.fixed_cost * @@params[:fixed_cost_100]
      var_cost += (f.flight_time/60) * @@params[:var_cost_100] * f.aircraft.var_cost
    end

    winst = omzet - fixed_cost - var_cost
    return {:winst => winst,:omzet => omzet,:fixed_cost => fixed_cost,:var_cost => var_cost,:spill => spill,:params => @@params}
  end
end

class Assignment
  # Fleet class holds all the plane schedules of every fleet
  class Fleet
    attr_accessor :size, :schedules, :ba_code
    
    def initialize(ba_code,size)
      @ba_code = ba_code
      @size = size
      clear_schedules!
    end
    
    def clear_schedules!
      @schedules = []
      @size.times { |nr| @schedules << Schedule.new(nr) }      
    end
    
    def fits?(flight,rotation=Assignment::params[:rotation])
      @schedules.any? { |schedule| schedule.fits?(flight,rotation) }
    end
    
    # try to fit the flight in a schedule, will return true if it fits, false if it doesn't 
    def fit_flight(flight,rotation=Assignment::params[:rotation])
      @schedules.detect { |schedule| schedule.fit_flight(flight,rotation) } != nil
    end # end method
  end # end Fleet
end # end Assignment

class Assignment
  class Fleet
    # The individual schedule of a plane
    # Includes all the scheduled flights
    class Schedule
      attr_accessor :flights, :number
      
      def initialize(number)
        @number = number
      end
      
      # add flight without checking
      def add_flight(flight)
        @flights << flight
        # remember in which schedule the flight is located
        flight.schedule_location = self.number
      end
      
      def remove_flight(flight)
        @flights.delete(flight)
      end
      
      def fit_flight(flight,rotation=Assignment::params[:rotation])
        if fits?(flight,rotation)
          add_flight(flight)
          return true
        else
          return false
        end
      end
      
      # check of er nog plaats is voor deze flight
      def fits?(flight,rotation=Assignment::params[:rotation])
        (@flights ||= []).empty? || @flights.all? {|f| ((f.arrival_time + rotation) < flight.departure_time) || ((flight.arrival_time + rotation) < f.departure_time) }
      end
      
      def to_divs(starting_date)
        return '' if @flights.nil? || @flights.empty?
        returning = ''
        prev_arr_time = nil
        @flights.sort_by { |f| f.departure_time}.each do |f|
          # set prev arrival_time to midnight if it hasn't been set
          prev_arr_time = starting_date unless prev_arr_time
          # set left and width in pixels according (1px = 5minutes)
          left = ((f.departure_time - prev_arr_time).abs / (5*60).to_f).round
          width = ((f.arrival_time - f.departure_time) / (5*60).to_f).round
          tooltip = "flight #{f.id}: #{f.departure_time}, #{f.arrival_time}"
          style = "flight #{f.haul == "Medium" ? 'medium_haul' : ''}"
          returning << "<div class='#{style}' title='#{tooltip}' style='width: #{width}px; margin-left: #{left}px; opacity: #{f.load_factor}'>#{f.spill == 0 ? '&nbsp;' : f.spill}</div>"
          prev_arr_time = f.arrival_time
        end
        return returning
      end
    end
  end
end