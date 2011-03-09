class AddWithAndHeightToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :width, :int
    add_column :photos, :height, :int
    add_column :photos, :medium_width, :int
    add_column :photos, :medium_height, :int
    add_column :photos, :thumb_width, :int
    add_column :photos, :thumb_height, :int
  end

  def self.down
    remove_column :photos, :thumb_height
    remove_column :photos, :thumb_width
    remove_column :photos, :medium_height
    remove_column :photos, :medium_width
    remove_column :photos, :height
    remove_column :photos, :width
  end
end
