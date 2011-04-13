class VideoCapture < ActiveRecord::Base
  belongs_to :video
  has_attached_file :thumbnail, :styles => {
    :original => {
      :geometry => '150x150>',
    },
  }, :convert_options => {
    :original => ['-strip', '-quality 50']
  }
end
