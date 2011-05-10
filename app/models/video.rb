require 'RMagick'
include Magick

class Video < Media
  has_attached_file :image, :styles => {
    :theora => {
      :geometry => '700',
      :format => :ogv,
    },
    :h264 => {
      :geometry => '700',
      :format => :mp4,
    }
  }, :processors => [:video_transcoder]

  has_many :video_captures, :dependent => :destroy, :order => :sort

  def self.add_or_update(file, force_update = false)
    v = Video.get_by_path file
    stat = File::Stat.new file
    if(v.nil?)
      v = Video.new
    else
      if(stat.mtime < v.updated_at && !force_update)
        return v
      end
    end
    v.path = file
    v.name = File.basename file
    v.taken_at = stat.ctime
    v.save
    v.generate_captures
    thumb_path = v.video_captures.first.thumbnail.path
    t = Image.read(thumb_path).first
    v.thumb_width = t.columns
    v.thumb_height = t.rows
    t.destroy!
    v.thumb_size = File.stat(thumb_path).size
    f = File.open(v.path)
    v.image = f
    v.save
    v
  end

  def generate_captures
    video_captures.each do |vc|
      vc.destroy
    end
    Dir.mktmpdir do |dir|
      system("ffmpeg -i '#{path}' -r 0.25 #{dir}/%d.jpg")
      Dir.foreach(dir) do |file|
        next unless file.ends_with?"jpg"
        vc = video_captures.build
        vc.sort = file.split('.').first
        vc.save
        File.open "#{dir}/#{file}" do |cap|
          vc.thumbnail = cap
        end
        vc.save
      end
    end
  end
end
