module Paperclip
  class VideoTranscoder < Processor
    attr_accessor :geometry, :format

    def initialize(file, options = {}, attachment = nil)
      super
      @geometry = options[:geometry]
      @format = options[:format]
      @basename = File.basename(file.path, File.extname(file.path))
      @path = File.expand_path(file.path)
      @attachment = attachment
    end

    def make
      dst = Tempfile.new([ @basename, @format ].compact.join("."))
      dst.binmode
      cmd = "ffmpeg"
      opts = ""
      if(@format == :ogv)
        cmd = "ffmpeg2theora"
        opts = "--max_size #{@geometry}x#{@geometry} #{@path} -o #{File.expand_path(dst.path)}"
      elsif(@format == :mp4)
        x,y = VideoTranscoder.calculate_x_y(@attachment.instance.thumb_width, @attachment.instance.thumb_height, @geometry).map { |i|
          i = i.to_i
          if(i % 2 == 1)
            i = i.succ
          end
          i
        }
        opts = "-i #{@path} -acodec libfaac -ab 128kb -ac 2 -ar 48000 -vcodec libx264 -level 21 -b 1500kb -coder 0 -f psp -flags +loop -trellis 2 -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 -g 13 -y -cmp +chroma -me_method hex -subq 7 -me_range 16 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -b_strategy 1 -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -bf 0 -refs 1 -directpred 1 -trellis 1 -flags2 +bpyramid+wpred+dct8x8+fastpskip -wpredp 2 -s #{x}x#{y} #{File.expand_path(dst.path)}"
      else
        rails PaperclipError, "unrecognized format: #{@format}"
      end
      begin
        Paperclip.run(cmd, opts)
        if(@format == :mp4)
          dst2 = Tempfile.new([ @basename, @format ].compact.join("."))
          dst2.binmode
          Paperclip.run('qt-faststart', "#{File.expand_path(dst.path)} #{File.expand_path(dst2.path)}")
          dst = dst2
        end
      rescue PaperclipCommandLineError
        raise PaperclipError, "error transcoding video"
      end
      dst
    end

    def self.calculate_x_y(x, y, pixels)
      factor = [x, y].max / pixels.to_f
      [x / factor, y / factor]
    end
  end
end
