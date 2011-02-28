require 'RMagick'
include Magick

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :photos
  acts_as_nested_set
  has_one :thumbnail

  def get_first_photo
    Photo.find_by_sql("select p.* from photos p join photos_tags pt on pt.photo_id = p.id where pt.tag_id = #{id} order by p.taken_at desc limit 1").first
  end

  def thumb_id=(id)
    self['thumb_id'] = id
    save
    generate_thumbnail
  end

  def thumb_width=(width)
    self['thumb_width'] = width
    save
    generate_thumbnail
  end

  def thumb_height=(height)
    self['thumb_height'] = height
    save
    generate_thumbnail
  end

  def thumb_x1=(x1)
    self['thumb_x1'] = x1
    save
    generate_thumbnail
  end

  def thumb_y1=(y1)
    self['thumb_y1'] = y1
    save
    generate_thumbnail
  end

  def generate_thumbnail()
    if(thumb_id.nil? || thumb_width.nil? || thumb_height.nil? || thumb_x1.nil? || thumb_y1.nil?)
      return false
    end
    image = Image.from_blob(Photo.find(thumb_id).medium_image.image).first
    temp_thumb = image.crop(thumb_x1, thumb_y1, thumb_width, thumb_height)
    temp_thumb.scale!(75,75)
    thumb = Thumbnail.find_or_create_by_tag_id id
    thumb.image = temp_thumb.to_blob { self.quality = 50 }
    thumb.tag_id = id
    thumb.save
  end
end
