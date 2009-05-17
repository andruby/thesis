# The assignment class holds an unsorted list of flights
# And sorted fleet classes
class Assignment
  attr_accessor :fleets, :flights, :available_craft
  
  def flight_with_id(id)
    @flights.find {|f| f.id == id }
  end
  
  class NoRoomForFlight < Exception; end;
  
  def initialize(flights,available_craft=nil)
    # set available craft to all craft if it is null
    @available_craft = (available_craft || AircraftType.find(:all, :conditions => ["count > 0"], :order => "id DESC"))
    @flights = flights
    @fleets = ActiveSupport::OrderedHash.new
    @available_craft.each do |craft|
      @fleets[craft.ba_code] = Fleet.new(craft.ba_code,craft.count) unless craft.count < 1
    end
  end
  
  # tel het aantal swaps
  # geeft een array terug [family,no-family] 
  def swap_count
    fam, nofam = 0, 0
    @flights.each do |flight|
      if flight.original_aircraft.ba_code != '146' && flight.assigned_aircraft && (flight.original_aircraft.ba_code != flight.assigned_aircraft.ba_code)
        flight.original_aircraft.family == flight.assigned_aircraft.family ? fam+=1 : nofam += 1
      end
    end
    return [fam,nofam]
  end
  
  # find all flights with spill and sort them by spill
  def flights_with_spill
    @flights.select {|f| f.spill > 0 }.collect { |f| [f.spill,f] }.sort_by(&:first).reverse
  end
  
  # shortcut method for easy access to the schedule where a flight is currently scheduled
  def schedule_for(flight)
    @fleets[flight.aircraft.ba_code].schedules[flight.schedule_location]
  end
  
  # fit a flight in the first  schedule where it fits
  def fit_flight(flight,surpress_errors=false)
    ba_code = flight.aircraft.ba_code
    fit = @fleets[ba_code].fit_flight(flight,AssignmentParameters.rotation_time_bru)
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
  def results(original=false)
    # zet alle stats op 0
    spill_cost, fixed_cost, var_cost, swap_cost = 0, 0, 0, 0
    # om makkelijker toegankelijk te maken hieronder
    spill_price = {"Short" => AssignmentParameters.spill_short, "Medium" => AssignmentParameters.spill_medium}
    total_spill = {"Short" => 0, "Medium" => 0}

    @flights.each do |f|
      [f.pax_1,f.pax_2].each do |pax|
        if pax >= f.capacity(original)
          # er is spill
          spill = pax - f.capacity(original)
          total_spill[f.haul] += spill
          spill_cost += spill_price[f.haul] * spill
        end
      end
      # Kosten toevoegen
      fixed_cost += 2 * (f.aircraft(original).fixed_cost/100.0) * AssignmentParameters.fixed_cost_100
      var_cost += (f.flight_time/(60*60)) * AssignmentParameters.var_cost_100 * (f.aircraft(original).var_cost/100.0)
      swap_cost += f.swap_penalty unless original
    end

    total_cost = fixed_cost + var_cost + spill_cost + swap_cost
    return {:total_cost => total_cost,:spill_cost => spill_cost,:fixed_cost => fixed_cost,:var_cost => var_cost, :swap_cost => swap_cost,:spill => total_spill,:params => AssignmentParameters.all}
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
    
    def fits?(flight,rotation = AssignmentParameters.rotation_time_bru)
      @schedules.any? { |schedule| schedule.fits?(flight,rotation) }
    end
    
    # try to fit the flight in a schedule, will return true if it fits, false if it doesn't 
    def fit_flight(flight,rotation = AssignmentParameters.rotation_time_bru)
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
      
      def fit_flight(flight,rotation = AssignmentParameters.rotation_time_bru)
        if fits?(flight,rotation)
          add_flight(flight)
          return true
        else
          return false
        end
      end
      
      # check of er nog plaats is voor deze flight
      def fits?(flight,rotation = AssignmentParameters.rotation_time_bru)
        (@flights ||= []).empty? || @flights.all? {|f| ((f.arrival_time + rotation) <= flight.departure_time) || ((flight.arrival_time + rotation) < f.departure_time) }
      end
      
      def to_divs(starting_date)
        return '' if @flights.nil? || @flights.empty?
        returning = ''
        prev_arr_time = nil
        @flights.sort_by { |f| f.departure_time}.each do |f|
          # set prev arrival_time to midnight if it hasn't been set
          prev_arr_time = starting_date.at_midnight unless prev_arr_time
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