require 'RMagick'
include Magick
require 'find'

class Photo < ActiveRecord::Base
  has_and_belongs_to_many :tags, :order => "lft asc"
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
      exif.orientation = ""
      exif.save
      p.rotate "right"
    elsif(exif.orientation.eql? "Rotate 90 CCW")
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
      join = join_for_tags(tags)
      count = Photo.count_by_sql("select count(1) from (select count(1) from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false group by p.id having count(pt_group.photo_id) >= #{tags.count}) as query")
      photos = Photo.paginate_by_sql ["select p.* from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false group by p.id having count(pt_group.photo_id) >= #{tags.count} order by p.taken_at #{sort}"],
        :page => page,
        :total_entries => count
    end
    [photos,count]
  end

  def self.join_for_tags(tags = [])
    join = ""
    tags.each do |tag|
      join += " join photos_tags pt_#{tag} on pt_#{tag}.photo_id = p.id and pt_#{tag}.tag_id = #{tag}"
    end
    join
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
      join = join_for_tags(tags)
      photo = Photo.find_by_sql("select p.* from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false and p.taken_at #{symbol} '#{taken_at}' group by p.id having count(pt_group.photo_id) >= #{tags.count} order by p.taken_at #{sort} limit 1").first
    end
    photo
  end

  def self.get_raw_histogram(tags = [])
    month_data = {}
    first_year = nil
    first_month = nil
    last_year = nil
    last_month = nil
    max_count = 0
    num_counts = 0
    raw_months_data = nil
    if(tags.nil? || tags.empty?)
      raw_months_data = connection.execute("select count(id),date_format(taken_at, '%Y-%m') as taken_month from photos where deleted = false group by taken_month")
    else
      join = join_for_tags(tags)
      raw_months_data = connection.execute("select count(p2.id),date_format(p2.taken_at, '%Y-%m') as taken_month from (select p.id,p.taken_at from photos p #{join} join photos_tags pt_group on pt_group.photo_id = p.id where p.deleted = false group by p.id having count(pt_group.photo_id) >= #{tags.count}) as p2 group by taken_month")
    end
    while(data = raw_months_data.fetch_row)
      count,date = data
      count = count.to_i
      year,month = date.split('-')
      year = year.to_i
      month = month.to_i
      if(first_year.nil?)
        first_year = year
        first_month = month
      end
      last_year = year
      last_month = month
      if(month_data[year].nil?)
        month_data[year] = {}
      end
      month_data[year][month] = count
      max_count = [max_count, count].max
      num_counts += 1
    end
    return [month_data, {:first_year => first_year, :first_month => first_month, :last_year => last_year, :last_month => last_month, :max_count => max_count, :num_counts => num_counts}]
  end

  def self.get_histogram_data(tags = [], sort = "desc")
    month_data,meta = get_raw_histogram(tags)
    data = []
    for year in meta[:first_year]..meta[:last_year]
      first_lmonth = 1
      last_lmonth = 12
      if(year.eql?meta[:first_year])
        first_lmonth = meta[:first_month]
      end
      if(year.eql?meta[:last_year])
        last_lmonth = meta[:last_month]
      end
      for month in first_lmonth..last_lmonth
        count = 0
        if(month_data[year][month])
          count = month_data[year][month]
        end
        data.push count
      end
    end
    tmp_data = []
    page = 1.0
    if(sort.eql?"desc")
      data = data.reverse
    end
    data.each do |data_i|
      tmp_data.push(page.to_i)
      page += data_i.to_f / per_page.to_f
    end
    if(sort.eql?'desc')
      return tmp_data.reverse
    else
      return tmp_data
    end
  end

  def self.get_histogram(tags = [], sort = "desc", slice = 0)
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    month_data,meta = get_raw_histogram(tags)
    height = 100.0
    width = 900.0
    factor = meta[:max_count] / height
    each_width = width / meta[:num_counts]
    images = []

    x_position = each_width / 2
    y_position = 125
    slice_count = 0

    for year in meta[:first_year]..meta[:last_year]
      first_lmonth = 1
      last_lmonth = 12
      if(year.eql?meta[:first_year])
        first_lmonth = meta[:first_month]
      end
      if(year.eql?meta[:last_year])
        last_lmonth = meta[:last_month]
      end
      for month in first_lmonth..last_lmonth
        image = nil
        puts "#{slice_count} #{slice}"
        if(slice_count == slice)
          image = Image.new(each_width, height + 50) {
            self.format = 'png'
          }
          gc = Draw.new
          gc.stroke('black')
          gc.stroke_width(each_width / 2)
          count = 0
          if(month_data[year][month])
            count = month_data[year][month]
          end
          offset = count / factor
          gc.line(x_position, y_position, x_position, y_position - offset)
          gc.annotate(image, each_width, 20, x_position - each_width / 5, y_position - offset, "#{count}") do
            self.pointsize = [each_width / 4, 30].min
          end
          gc.annotate(image, each_width, 20, x_position - each_width / 3, y_position + 20, "#{year}-#{month}") do
            self.pointsize = [each_width / 5, 25].min
          end
          gc.draw(image)
        end
        images.push image
        slice_count += 1
      end
    end
    return images[slice].to_blob
  end
end
