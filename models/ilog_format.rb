# easy interface with Ilog
module IlogFormat
  # Map waar alle shared_data met ilog wordt gedaan
  SharedDataDir = '/Volumes/andrew/unief/thesis - fleet assignment/ILOG/shared_data/'
  
  def self.read_from_ilog(type,config_name,&block)
    File.open(self.shared_filename(type,config_name),'r') do |file|
      yield(file)
    end
  end
  
  def self.write_to_ilog(type,config_name,&block)
    File.open(self.shared_filename(type,config_name),'w') do |file|
      yield(file)
    end
    puts "Saved file to #{self.shared_filename(type,config_name)}"
  end
  
  def self.shared_filename(type,config_name)
    File.join(SharedDataDir,type.to_s,config_name.to_s+'.dat')
  end
end