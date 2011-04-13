require 'RMagick'
include Magick

class Video < Media
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
    v.deleted = false
    v.taken_at = stat.ctime
    v.save
    v.generate_captures
    path = v.video_captures.first.thumbnail.path
    t = Image.read(path).first
    v.thumb_width = t.columns
    v.thumb_height = t.rows
    t.destroy!
    v.thumb_size = File.stat(path).size
    v.save
    v
  end

  def generate_captures
    Dir.mktmpdir do |dir|
      system("ffmpeg -i #{path} -r 0.25 #{dir}/%d.jpg")
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
