class Tag < ActiveRecord::Base
  has_and_belongs_to_many :photos
  acts_as_nested_set
end
