class Media < ActiveRecord::Base
  has_and_belongs_to_many :tags, :order => :lft
  acts_as_trashable

  scope :tags, lambda { |tags|
    joins(join_for_tags(tags)).group('media.id').having("count(pt_group.media_id) >= #{tags.count}")
  }

  def update_media
    self.class.add_or_update(path, true)
  end

  def self.get_by_path(path)
    with_exclusive_scope{Media.find_by_path path}
  end

  def display_tags(trimcount = nil)
    display = tags.map{ |tag| tag.name }.join(', ')
    if(!trimcount.nil? && display.mb_chars.size > trimcount)
      display = display.mb_chars.slice(0, trimcount) + "..."
    end
    display
  end

  def self.get_pagination(page, tags, sort = "desc")
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(tags.nil? || tags.empty?)
      count = Media.count
      photos = Media.order("taken_at #{sort}").includes(:tags).paginate(:page => page, :total_entries => count)
    else
      count = Media.tags(tags).count.size
      photos = Media.tags(tags).includes(:tags).order("media.taken_at #{sort}").paginate(:page => page, :total_entries => count)
    end
    [photos,count]
  end

  def self.join_for_tags(tags = [])
    tags = tags.map { |tag| tag.to_i }
    join = "join media_tags pt_group on pt_group.media_id = media.id"
    tags.each do |tag|
      join += " join media_tags pt_#{tag} on pt_#{tag}.media_id = media.id and pt_#{tag}.tag_id = #{tag}"
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
      photo = Media.where("taken_at #{symbol} '#{taken_at}'").order("taken_at #{sort}").first
    else
      photo = Media.where("taken_at #{symbol} '#{taken_at}'").order("taken_at #{sort}").tags(tags).first
    end
    photo
  end

  def self.get_first(sort = "desc", tags = [])
    if(!sort.eql?("desc") && !sort.eql?("asc"))
      sort = "desc"
    end
    if(tags.nil? || tags.empty?)
      photo = Media.order("taken_at #{sort}").first
    else
      photo = Media.tags(tags).order("taken_at #{sort}").first
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
      raw_months_data = connection.execute("select count(id),date_format(taken_at, '%Y-%m') as taken_month from media group by taken_month")
    else
      raw_months_data = connection.execute("select count(p2.id),date_format(p2.taken_at, '%Y-%m') as taken_month from (select media.id,media.taken_at from media #{join_for_tags(tags)} group by media.id having count(pt_group.media_id) >= #{tags.count}) as p2 group by taken_month")
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
      if month_data[year].nil?
        month_data[year] = {}
      end
      for month in first_lmonth..last_lmonth
        if month_data[year][month].nil?
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
        data.push({:count => count, :month => month, :year => year})
      end
    end
    page = 1.0
    if(sort.eql?"desc")
      data = data.reverse
    end
    data.each do |data_i|
      data_i[:page] = page.to_i
      page += data_i[:count].to_f / per_page.to_f
    end
    if(sort.eql?'desc')
      return [meta[:max_count], data.reverse]
    else
      return [meta[:max_count], data]
    end
  end

  def self.get_histogram(count, year, month, max, current)
    height = 100.0
    width = 900.0
    factor = max / height
    each_width = 60
    images = []

    x_position = each_width / 2
    y_position = 125

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
    offset = count / factor
    gc.line(x_position, y_position, x_position, y_position - offset)
    gc.annotate(image, each_width, 20, x_position - each_width / 5, y_position - offset - 5, "#{count}") do
      self.pointsize = [each_width / 4, 30].min
    end
    gc.annotate(image, each_width, 20, x_position - each_width / 2, y_position + 20, "#{year}-#{Date::ABBR_MONTHNAMES[month]}") do
      self.pointsize = [each_width / 5, 25].min
    end
    gc.draw(image)
    return image.to_blob
  end
end
