class TagSweeper < ActionController::Caching::Sweeper
  observe Tag

  def self.update
    puts "kaka"
  end

  def after_create(tag)
    expire
  end

  def after_save(tag)
    expire
  end

  def after_destroy(tag)
    expire
  end

  def expire
    @controller ||= ActionController::Base.new
    @controller.expire_fragment(/tags_.*/)
  end
end
