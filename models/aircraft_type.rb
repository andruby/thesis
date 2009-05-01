# Model for aircraft types
#
# ATTRIBUTES
# range in kms
# fixed_cost in euro and per flight leg
# variable cost also in euro, per minute and per passenger
class AircraftType < ActiveRecord::Base
  has_many :flight_leg_groups
  
end