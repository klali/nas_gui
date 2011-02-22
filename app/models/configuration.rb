class Configuration < ActiveRecord::Base
  def self.get_path
    return Configuration.first.path
  end
end
