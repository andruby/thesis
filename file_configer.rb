# Class voor het herschrijven van de config file
class FileConfiger
  attr_accessor :filename, :replace_data, :start_id, :stop_id
  
  def initialize(_filename,_start_id=['<!-- START_',' -->'],_stop_id=['<!-- STOP_',' -->'])
    self.filename = _filename
    self.replace_data = []
    self.start_id = _start_id
    self.stop_id = _stop_id
  end
  
  def queue_replace(comment_name,data)
    self.replace_data << [comment_name,data]
  end
  
  def write_it
    puts "start writing"
    buffer = File.new(filename,'r').read
    replace_data.each do |rep|
      start_identifier = start_id.first + rep.first.upcase + start_id.last
      stop_identifier = stop_id.first + rep.first.upcase + stop_id.last
      buffer.gsub!(/#{Regexp.escape(start_identifier)}.*#{Regexp.escape(stop_identifier)}/m,"#{start_identifier}\n#{rep.last}\n#{stop_identifier}")
    end
    File.open(filename,'w') {|fw| fw.write(buffer) }
    puts "done"
  end
end