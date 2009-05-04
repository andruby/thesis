require 'rubygems'
require 'activerecord'
require 'geokit'
require 'geokit-rails/lib/geokit-rails.rb'

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