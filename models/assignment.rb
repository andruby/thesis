# The assignment class holds an unsorted list of flights
# And sorted fleet classes
class Assignment
  attr_accessor :fleets, :flights
  
  class NoRoomForFlight < Exception; end;
  
  def initialize(flights,available_craft=nil)
    # set available craft to all craft if it is null
    available_craft = AircraftType.find(:all, :conditions => ["count > 0"], :order => "id") unless available_craft
    @flights = flights
    @fleets = ActiveSupport::OrderedHash.new
    available_craft.each do |craft|
      @fleets[craft.ba_code] = Fleet.new(craft.ba_code,craft.count) unless craft.count < 1
    end
  end
  
  def fit_flight(flight,rotation)
    ba_code = flight.aircraft.ba_code
    reply = @fleets[ba_code].fit_flight(flight,rotation)
    raise NoRoomForFlight, "No room for flight #{flight}" if reply.nil? 
  end
  
  def schedule!(rotation=30.minutes)
    # clear previous schedules
    @fleets.each_value { |fleet| fleet.clear_schedules! }
    # reschedule
    @flights.each { |flight| self.fit_flight(flight,rotation) }  
  end
  
  # bereken de omzet,kosten en winst
  def results(fixed_cost_100=21,var_cost_100=0.56,price_short_haul=100,price_medium_haul=200)
    # save parameters
    params = {:fixed_cost_100 => fixed_cost_100,:var_cost_100 => var_cost_100,
              :price_short_haul => price_short_haul,:price_medium_haul=>price_medium_haul}
    # zet alle stats op 0
    omzet, fixed_cost, var_cost = 0, 0, 0
    # om makkelijker toegankelijk te maken hieronder
    price = {"Short" => price_short_haul, "Medium" => price_medium_haul}
    spill = {"Short" => 0, "Medium" => 0}

    @flights.each do |flight|
      [flight.demand_1,flight.demand_2].each do |demand|
        if flight.capacity >= demand
          # de vraag wordt voldaan
          omzet += price[flight.haul] * demand
        else
          # er is spill
          omzet += price[flight.haul] * flight.capacity
          spill[flight.haul] += demand - flight.capacity
        end
      end
      # Kosten toevoegen
      fixed_cost += 2 * flight.aircraft.fixed_cost * fixed_cost_100
      var_cost += (flight.flight_time/60) * var_cost_100 * flight.aircraft.var_cost
    end

    winst = omzet - fixed_cost - var_cost
    return {:winst => winst,:omzet => omzet,:fixed_cost => fixed_cost,:var_cost => var_cost,:spill => spill,:params => params}
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
      @size.times { @schedules << Schedule.new }      
    end
    
    # try to fit the flight in a schedule, will return nil if there is no room
    def fit_flight(flight,rotation)
      @schedules.detect { |schedule| schedule.fit_flight(flight,rotation) }
    end # end method
  end # end Fleet
end # end Assignment

class Assignment
  class Fleet
    # The individual schedule of a plane
    # Includes all the scheduled flights
    class Schedule
      attr_accessor :flights
      
      def fit_flight(flight,rotation)
        if (@flights ||= []).empty? || fits?(flight,rotation)
          @flights << flight
          return true
        else
          return false
        end
      end
      
      # check of er nog plaats is voor deze flight
      def fits?(flight,rotation)
        @flights.all? {|f| ((f.arrival_time + rotation) < flight.departure_time) || ((flight.arrival_time + rotation) < f.departure_time) }
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