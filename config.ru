require 'rubygems'
require 'sinatra'
  
root_dir = File.dirname(__FILE__)

Sinatra::Application.default_options.merge!(
  :views    => File.join(root_dir, 'views'),
  :app_file => File.join(root_dir, 'assignment_viewer.rb'),
  :run => false,
  :env => :production
)

require 'assignment_viewer.rb'
run Sinatra.application