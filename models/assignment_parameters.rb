class AssignmentParameters  
  # rotatietijd in minuten in Brussel
  cattr_accessor :rotation_time_bru
  
  # rotatietijd in minuten in andere luchthavens
  cattr_accessor :rotation_time_external
  
  # vaste kosten voor 1 flight leg gevlogen door een 737-400
  cattr_accessor :fixed_cost_100
  
  # variabele kosten voor 1 minuut gevlogen door een 737-400
  cattr_accessor :var_cost_100
  
  # spill kost per passagier voor korte vluchten
  cattr_accessor :spill_short
  
  # spill kost per passagier voor medium vluchten
  cattr_accessor :spill_medium
  
  # bewaart de filename waarvan geladen werd
  cattr_accessor :config_name
    
  # read data from ilog format
  def self.from_ilog(config_name='default')
    IlogFormat.read_from_ilog(:parameters,config_name) do |file|
      while((line = file.gets))
        if line.include?('=')
          key, value = line.strip.split(' = ')
          class_variable_set("@@#{key}", value.gsub(';','').to_i)
        end
      end
    end
    @@config_name = config_name
    @@rotation_time_bru = @@rotation_time_bru.minutes
    @@rotation_time_external = @@rotation_time_external.minutes
  end
  
  def self.all
    returning = {}
    class_variables.each {|cv| returning[cv.to_s.gsub('@@','')] = class_variable_get(cv) }
    returning
  end
end