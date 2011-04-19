module Paperclip
  class VideoTranscoder < Processor
    attr_accessor :geometry, :format

    def initialize(file, options = {}, attachment = nil)
      super
      @geometry = options[:geometry]
      @format = options[:format]
      @basename = File.basename(file.path, File.extname(file.path))
      @path = File.expand_path(file.path)
    end

    def make
      dst = Tempfile.new([ @basename, @format ].compact.join("."))
      dst.binmode
      cmd = "ffmpeg"
      opts = ""
      if(@format == :ogv)
        cmd = "ffmpeg2theora"
        opts = "--max_size #{@geometry} #{@path} -o #{File.expand_path(dst.path)}"
      end
      begin
        Paperclip.run(cmd, opts)
      rescue PaperclipCommandLineError
        raise PaperclipError, "error transcoding video"
      end
      dst
    end
  end
end
