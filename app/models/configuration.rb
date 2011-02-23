class Configuration < ActiveRecord::Base
  def self.get_photo_path
    return Configuration.find_by_key('photos.path').value
  end
end
