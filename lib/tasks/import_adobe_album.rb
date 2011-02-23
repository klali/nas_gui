require 'csv'

tags_hash = {}

CSV.foreach('/home/kllin/private/photos-import/folder-utf.txt') do |row|
  next if row[1].empty?
  tags_hash[row[0].to_i] = row[1]
end

CSV.foreach('/home/kllin/private/photos-import/image-utf.txt') do |row|
  pic_name = row[5]
  tags_in = row[6]
  tags = []

  tags_in.split(" ").each do |tag_id|
    next if tag_id.eql?"00"
    tag_name = tags_hash[tag_id.hex]
    if(!tag_name.nil?)
      tag = Tag.find_by_name tag_name
      if(tag.nil?)
        puts "creating #{tag_name}"
        tag = Tag.new
        tag.name = tag_name
        tag.save!
      end
      tags.push tag
    end
  end

  files = Dir.glob(Configuration.get_photo_path + "**/#{pic_name}", File::FNM_CASEFOLD)
  if(files.size == 1)
    path = files.first
    if(path.ends_with?(".jpg") || path.ends_with?(".JPG"))
      photo = Photo.add_or_update(path)
      photo.tags = tags
      puts "imported #{pic_name}"
    else
      puts "not importing #{pic_name}"
    end
  elsif(files.size == 0)
    puts "couldn't find #{pic_name}"
  else
    raise ArgumentError, "several results for #{pic_name}"
  end
end
