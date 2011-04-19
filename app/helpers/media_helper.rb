module MediaHelper
  def thumbnail_for(media)
    if(media.is_a?Photo)
      url = media.image.url(:thumbnail)
    elsif(media.is_a?Video)
      url = media.video_captures.first.thumbnail.url
    end
    image_tag(url, :title => media.path, :border => 0, :class => 'image_preview')
  end

  def video_preview_for(media)
    thumbs = ""
    media.video_captures.each do |vc|
      next if vc.sort == 1
      thumbs += "'#{vc.thumbnail.url}',"
    end
    "cjImageVideoPreviewer({
      'images': [
        #{thumbs} 
      ], 'showProgress': false
    });"
  end
end
