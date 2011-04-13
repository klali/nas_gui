require 'RMagick'
include Magick

class Photo < Media
  has_attached_file :image, :styles => {
    :medium => {
      :geometry => '700x700>',
    },
    :thumbnail => {
      :geometry => '150x150>',
    },
  }, :convert_options => {
    :medium => ['-strip', '-quality 75'],
    :thumbnail => ['-strip', '-quality 50']
  }

  def self.add_or_update(file, force_update = false)
    p = Photo.get_by_path file
    stat = File::Stat.new file
    if(p.nil?)
      p = Photo.new
    else
      if(stat.mtime < p.updated_at && !force_update)
        return p
      end
    end
    p.path = file
    p.name = File.basename file
    p.deleted = false
    exif = MiniExiftool.new file
    ex_date = exif.DateTimeOriginal
    if(ex_date.nil?)
      p.taken_at = stat.ctime
    else
      p['taken_at'] = ex_date
    end

    i = File.open(file, 'rb')
    p.image = i
    p.save
    if(exif.orientation.eql? "Rotate 90 CW")
      exif.orientation = ""
      exif.save
      p.rotate "right"
    elsif(exif.orientation.eql? "Rotate 90 CCW")
      exif.orientation = ""
      exif.save
      p.rotate "left"
    end
    p.set_width_and_height
    p.set_sizes
    p
  end

  def set_width_and_height
    i = Image.read(path).first
    self.width = i.columns
    self.height = i.rows
    i.destroy!
    m = Image.read(image.path).first
    self.medium_width = m.columns
    self.medium_height = m.rows
    m.destroy!
    t = Image.read(image.path(:thumbnail)).first
    self.thumb_width = t.columns
    self.thumb_height = t.rows
    t.destroy!
    save
    self
  end

  def set_sizes
    self.medium_size = File.stat(image.path).size
    self.thumb_size = File.stat(image.path(:thumbnail)).size
    save
    self
  end

  def rotate(direction)
    if(direction.eql?("left"))
      angle = -90
    elsif(direction.eql?("right"))
      angle = 90
    else
      raise ArgumentError, "Only left or right are acceptable arguments."
    end
    exif = MiniExiftool.new path
    exif.orientation = ""
    exif.save
    i = Image.read(path).first
    i = i.rotate(angle)
    i.write(path)
    i.destroy!
    file = File.open path
    self.image = file
    file.close
    save
    set_width_and_height
    set_sizes
    self
  end

  def taken_at=(date)
    self['taken_at'] = date
    save
    exif = MiniExiftool.new path
    exif.date_time_original = date
    exif.save
  end
end
