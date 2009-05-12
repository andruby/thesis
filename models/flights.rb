# Class that holds an array of flights
# access them as a normal array: flights[flight_id]
class Flights < Array
  attr_accessor :start_date, :end_date, :session_name
  
  def initialize(_session_name,_start_date,_end_date)
    @session_name = _session_name
    @start_date = _start_date
    @end_date = _end_date
  end
  
  # write to ilog format
  def to_ilog(session_name=@session_name)
    IlogFormat.write_to_ilog(:flights,session_name) do |file|
      file.puts "/* Session name: #{session_name}"
      file.puts "* Created at: #{Time.now}"
      file.puts "* Loaded parameters: #{AssignmentParameters.config_name}"
      file.puts "* "
      file.puts "* start_date = #{@start_date};"
      file.puts "* stop_date = #{@end_date};"
      file.puts "*/"
      file.puts "flightLegs = {"
      self.each_with_index {|f,idx| file.puts f.to_ilog(idx,start_date.at_midnight) }
      file.puts "}"
    end
  end
  
  def self.from_ilog(session_name)
    IlogFormat.read_from_ilog(:flights,session_name) do |file|
      while((line = file.gets))
        # TODO: lees start en stop date en load de flights
      end
    end
  end
end