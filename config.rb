require 'rubygems'
require 'activerecord'
require 'yaml'

# require 'geokit'
# require 'geokit-rails/lib/geokit-rails.rb'

# Loads all model files
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }

def connect_to_db(db='thesis')
  ActiveRecord::Base.establish_connection(
     :adapter  => "postgresql",
     :host     => "localhost",
     :username => "thesis",
     :password => "thesis",
     :database => db.to_s,
     :encoding => "utf8"
  )
end

connect_to_db

# Handy yaml shortcuts
def load_from_yaml(yaml_file)
  File.open( yaml_file ) { |yf| YAML::load( yf ) }
end

# write flights to a yaml file
def write_to_yaml(data,yaml_file)
  File.open(yaml_file,'w') { |yf| YAML.dump(data,yf) }
end