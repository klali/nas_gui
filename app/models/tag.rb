require 'RMagick'
include Magick

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :media, :order => :taken_at
  acts_as_nested_set
  acts_as_trashable :excluded_attributes => [:lft, :rgt]
  has_attached_file :thumbnail

  default_scope order(:lft)

  scope :search, lambda { |name|
    where("upper(name) like upper('#{name}%')")
  }

  validates :name, :presence => true, :uniqueness => true, :format => {:with => /^[^\,]+$/, :message => "Tag name can't contain ','."}

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
    image = Image.read(Photo.find(thumb_id).image.path(:medium)).first
    temp_thumb = image.crop(thumb_x1, thumb_y1, thumb_width, thumb_height)
    temp_thumb.scale!(75,75)
    temp_thumb.strip!
    file = Tempfile.new(['thumbnail', '.jpg'])
    temp_thumb.write(file.path) { self.quality = 50 }
    self.thumbnail = file
    file.close
    file.unlink
    temp_thumb.destroy!
    save
  end

  def self.get_tag_data(tags = nil)
    if(tags.nil? || tags.empty?)
      return Tag.joins('join media_tags mt on tags.id = mt.tag_id').group('mt.tag_id').count
    else
      return Media.joins(Media.join_for_tags(tags)).group('pt_group.tag_id').count
    end
  end
end
