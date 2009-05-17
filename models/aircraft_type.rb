# Model for aircraft types
#
# ATTRIBUTES
# range in kms
# fixed_cost in euro and per flight leg
# variable cost also in euro, per minute and per passenger
class AircraftType < ActiveRecord::Base
  has_many :flight_leg_groups
  
  def family
    if ["AR8","AR1","146"].include?(ba_code)
      return 1
    elsif ["733","734"].include?(ba_code)
      return 2
    else
      return 0
    end
  end
end