require 'RMagick'
include Magick

class Photo < ActiveRecord::Base
  has_and_belongs_to_many :tags, :order => "lft asc"
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

  scope :tags, lambda { |tags|
    joins(join_for_tags(tags))
  }

  default_scope order(:taken_at)
  default_scope where(:deleted => false)

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

  def taken_at=(date)
    self['taken_at'] = date
    save
    exif = MiniExiftool.new path
    exif.date_time_original = date
    exif.save
  end

  def display_tags
    tags.map{ |tag| tag.name }.join(', ')
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

  def self.get_pagination(page, tags, sort = "desc")
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(tags.nil? || tags.empty?)
      count = Photo.count
      photos = Photo..order("taken_at #{sort}").includes(:tags).paginate(:page => page, :total_entries => count)
    else
      count = Photo.tags(tags).group("photos.id").having("count(pt_group.photo_id) >= #{tags.count}").count.size
      photos = Photo.tags(tags).group('photos.id').having("count(pt_group.photo_id) >= #{tags.count}").includes(:tags).order("photos.taken_at #{sort}").paginate(:page => page, :total_entries => count)
    end
    [photos,count]
  end

  def self.join_for_tags(tags = [])
    tags = tags.map { |tag| tag.to_i }
    join = "join photos_tags pt_group on pt_group.photo_id = photos.id"
    tags.each do |tag|
      join += " join photos_tags pt_#{tag} on pt_#{tag}.photo_id = photos.id and pt_#{tag}.tag_id = #{tag}"
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
      sort = "desc"
      symbol = '<'
    end
    get_one_by_symbol(symbol, sort, tags)
  end

  def get_one_by_symbol(symbol,sort,tags)
    if(tags.nil? || tags.empty?)
      photo = Photo.where("taken_at #{symbol} '#{taken_at}'").order("taken_at #{sort}").first
    else
      photo = Photo.where("taken_at #{symbol} '#{taken_at}'").order("taken_at #{sort}").tags(tags).group('photos.id').having("count(pt_group.photo_id) >= #{tags.count}").first
    end
    photo
  end

  def self.get_first(sort = "desc", tags = [])
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(tags.nil? || tags.empty?)
      photo = Photo.order("taken_at #{sort}").first
    else
      photo = Photo.tags(tags).group('photos.id').having("count(pt_group.photo_id) >= #{tags.count}").order("taken_at #{sort}").first
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
      raw_months_data = connection.execute("select count(p2.id),date_format(p2.taken_at, '%Y-%m') as taken_month from (select photos.id,photos.taken_at from photos #{join_for_tags(tags)} where photos.deleted = false group by photos.id having count(pt_group.photo_id) >= #{tags.count}) as p2 group by taken_month")
    end
    if(raw_months_data.num_rows == 0)
      return nil
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

    for year in first_year..last_year
      first_lmonth = 1
      last_lmonth = 12
      if(year.eql?first_year)
        first_lmonth = first_month
      end
      if(year.eql?last_year)
        last_lmonth = last_month
      end
      for month in first_lmonth..last_lmonth
        unless month_data[year][month]
          num_counts += 1
          month_data[year][month] = 0
        end
      end
    end

    return [month_data, {:first_year => first_year, :first_month => first_month, :last_year => last_year, :last_month => last_month, :max_count => max_count, :num_counts => num_counts}]
  end

  def self.get_histogram_data(tags = [], sort = "desc")
    month_data,meta = get_raw_histogram(tags)
    data = []
    if(month_data.nil?)
      return []
    end
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
        count = month_data[year][month]
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

  def self.get_histogram(tags = [], slice = 0, current = false)
    month_data,meta = get_raw_histogram(tags)

    height = 100.0
    width = 900.0
    factor = meta[:max_count] / height
    #each_width = width / meta[:num_counts]
    each_width = 60
    images = []

    x_position = each_width / 2
    y_position = 125
    slice_count = 0

    catch :break do
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
          if(slice_count == slice)
            image = Image.new(each_width, height + 50) {
              self.format = 'png'
            }
            gc = Draw.new
            if(current == "true")
              gc.stroke('green2')
            else
              gc.stroke('gray40')
            end
            gc.stroke_width(each_width / 2)
            count = month_data[year][month]
            offset = count / factor
            gc.line(x_position, y_position, x_position, y_position - offset)
            gc.annotate(image, each_width, 20, x_position - each_width / 5, y_position - offset - 5, "#{count}") do
              self.pointsize = [each_width / 4, 30].min
            end
            gc.annotate(image, each_width, 20, x_position - each_width / 2, y_position + 20, "#{year}-#{Date::ABBR_MONTHNAMES[month]}") do
              self.pointsize = [each_width / 5, 25].min
            end
            gc.draw(image)
            images.push image
            throw :break
          else
            images.push nil
            slice_count += 1
          end
        end
      end
    end
    return images[slice].to_blob
  end
end
