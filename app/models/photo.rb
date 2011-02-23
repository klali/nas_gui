require 'RMagick'
include Magick
require 'find'

class Photo < ActiveRecord::Base
  has_and_belongs_to_many :tags
  has_one :thumbnail
  has_one :medium_image

  def self.scan_directory
    scanned = 0
    Find.find(Configuration.get_photo_path) { |path|
      if FileTest.file?(path)
        if(path.ends_with?(".jpg") || path.ends_with?(".JPG"))
          p = add_or_update(path)
          scanned += 1
        end
      end
    }

    Photo.find_each(:conditions => {:deleted => false}, :batch_size => 100) { |photo|
      if files.find_index(photo.path).nil?
        photo.deleted = true
        photo.save
        scanned += 1
      end
    }
    scanned
  end

  def self.add_or_update(file, force_update = false)
    p = Photo.find_by_path file
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

    i = Image.read(file).first
    p.save
    p.thumbnail = scale_by_pixels(i, 150.0)
    p.medium_image = scale_by_pixels(i, 700.0)
    if(exif.orientation.eql? "Rotate 90 CW")
      puts "rotate CW"
      exif.orientation = ""
      exif.save
      p.rotate "right"
    elsif(exif.orientation.eql? "Rotate 90 CCW")
      puts "rotate CCW"
      exif.orientation = ""
      exif.save
      p.rotate "left"
    end
    p
  end

  def thumbnail=(image)
    thumb = Thumbnail.find_or_create_by_photo_id id
    thumb.image = image
    thumb.save
  end

  def medium_image=(image)
    medium = MediumImage.find_or_create_by_photo_id id
    medium.image = image
    medium.save
  end

  def self.scale_by_pixels(image, pixels)
    factor = [image.columns, image.rows].max / pixels
    if(factor == 0)
      raise "Failed to scale image"
    end
    return image.thumbnail(image.columns / factor, image.rows / factor).to_blob
  end

  def self.parse_exif_date(date)
    DateTime.strptime(date, "%Y:%m:%d %H:%M:%S")
  end

  def get_thumbnail
    Image.from_blob(thumbnail.image).first
  end

  def get_image
    Image.read(path).first
  end

  def get_mediumimage
    Image.from_blob(medium_image.image).first
  end

  def taken_at=(date)
    self['taken_at'] = date
    save
    exif = MiniExiftool.new path
    exif.date_time_original = date
    exif.save
  end

  def display_tags
    display = ""
    tags.each do |tag|
      if(!display.empty?)
        display += ", "
      end
      display += tag.name
    end
    display
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
    Photo.add_or_update(path, true)
  end

  def self.get_pagination(page, tags, sort = "desc")
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(tags.nil? || tags.empty?)
      count = Photo.count_by_sql("select count(id) from photos where deleted = false")
      photos = Photo.paginate_by_sql ["select p.* from photos p where deleted = false order by taken_at #{sort}"],
        :page => page,
        :total_entries => count
    else
      join = ""
      tags.each do |tag|
        join += " join photos_tags pt_#{tag} on pt_#{tag}.photo_id = p.id and pt_#{tag}.tag_id = #{tag}"
      end
      count = Photo.count_by_sql("select count(1) from (select count(1) from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false group by p.id having count(pt_group.photo_id) >= #{tags.count}) as query")
      photos = Photo.paginate_by_sql ["select p.* from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false group by p.id having count(pt_group.photo_id) >= #{tags.count} order by p.taken_at #{sort}"],
        :page => page,
        :total_entries => count
    end
    [photos,count]
  end

  def get_next(sort = "desc", tags = [])
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(sort.eql?"desc")
      symbol = '<'
    else
      symbol = '>'
    end
    get_one_by_symbol(symbol, sort, tags)
  end

  def get_previous(sort ="desc", tags = [])
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(sort.eql?"desc")
      sort = "asc"
      symbol = '>'
    else
      sort = "asc"
      symbol = '<'
    end
    get_one_by_symbol(symbol, sort, tags)
  end

  def get_one_by_symbol(symbol,sort,tags)
    if(tags.nil? || tags.empty?)
      photo = Photo.find_by_sql("select * from photos where taken_at #{symbol} '#{taken_at}' and deleted = false order by taken_at #{sort} limit 1").first
    else
      join = ""
      tags.each do |tag|
        join += " join photos_tags pt_#{tag} on pt_#{tag}.photo_id = p.id and pt_#{tag}.tag_id = #{tag}"
      end
      photo = Photo.find_by_sql("select p.* from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false and p.taken_at #{symbol} '#{taken_at}' group by p.id having count(pt_group.photo_id) >= #{tags.count} order by p.taken_at #{sort} limit 1").first
    end
    photo
  end
end
