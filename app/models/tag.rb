require 'RMagick'
include Magick

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :photos
  acts_as_nested_set
  has_attached_file :thumbnail

  def get_first_photo
    Photo.joins("join photos_tags pt on pt.photo_id = photos.id").where("pt.tag_id = #{id} and photos.deleted = false").order('photos.taken_at desc').first
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
    image = Image.read(Photo.find(thumb_id).image.path).first
    temp_thumb = image.crop(thumb_x1, thumb_y1, thumb_width, thumb_height)
    temp_thumb.scale!(75,75)
    temp_thumb.strip!
    file = Tempfile.new('thumbnail')
    file.write temp_thumb.to_blob { self.quality = 50 }
    self.thumbnail = file
    file.close
    file.unlink
    save
  end
end
