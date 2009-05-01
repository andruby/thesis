require 'rubygems'
require 'activerecord'
require 'geokit'
require 'geokit-rails/lib/geokit-rails.rb'

ActiveRecord::Base.establish_connection(
   :adapter  => "postgresql",
   :host     => "localhost",
   :username => "thesis",
   :password => "thesis",
   :database => "thesis",
   :encoding => "utf8"
)

# Loads all model files
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }