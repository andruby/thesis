require 'yaml'
require 'rubygems'
require 'sinatra'
require 'config'

class Assignment
  attr_accessor :fleets
  
  def initialize(available_craft)
    @fleets = {}
    available_craft.each do |craft|
      @fleets[craft.ba_code] = Fleet.new(craft.ba_code,craft.count) unless craft.count < 1
    end
  end
  
  def fit_flight(flight,rotation)
    ba_code = flight.aircraft.ba_code
    reply = @fleets[ba_code].fit_flight(flight,rotation)
    raise "No room for flight #{flight}" if reply.nil? 
  end
  
  class Fleet
    attr_accessor :size, :schedules, :ba_code
    
    def initialize(ba_code,size)
      @ba_code = ba_code
      @schedules = []
      size.times { @schedules << Schedule.new }
    end
    
    def fit_flight(flight,rotation)
      reply = @schedules.detect { |schedule| schedule.fit_flight(flight,rotation) }
      if reply.nil?
        puts "Add a new schedule for fleet #{flight.aircraft.ba_code}"
        @schedules << Schedule.new
        return @schedules.last.fit_flight(flight,rotation)
      else
        return true
      end
    end
    
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
          returning << "<div class='#{style}' title='#{tooltip}' style='width: #{width}px; margin-left: #{left}px'>&nbsp;</div>"
          prev_arr_time = f.arrival_time
        end
        return returning
      end
    end
  end
end

get '/' do
  # save file voor vluchten
  yaml_file = 'data/flights.yml'

  # load flights
  @flights = File.open( yaml_file ) { |yf| YAML::load( yf ) }
  @aircraft_types = AircraftType.all
  
  # assign flights to aircraft
  @assignment = Assignment.new(@aircraft_types)
  @flights.each { |flight| @assignment.fit_flight(flight,30*60) }
  #p @assignment.fleets['AR1'].schedules.first.flights.collect{|f| [f.departure_time,f.arrival_time]}
    
  erb :flight_table_view
end