class AddMediumImageToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :medium_image, :mediumblob
  end

  def self.down
    remove_column :photos, :medium_image
  end
end
