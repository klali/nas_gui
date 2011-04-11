class MediaSweeper < ActionController::Caching::Sweeper
  observe Photo

  def self.update
    puts "kaka"
  end

  def after_create(photo)
    expire
  end

  def after_save(photo)
    expire
  end

  def after_destroy(photo)
    expire
  end

  def expire
    @controller ||= ActionController::Base.new
    expire_fragment(/histogram.*/)
  end
end
