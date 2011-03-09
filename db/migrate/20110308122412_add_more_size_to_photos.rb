class AddMoreSizeToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :medium_size, :int
    add_column :photos, :thumb_size, :int
  end

  def self.down
    remove_column :photos, :thumb_size
    remove_column :photos, :medium_size
  end
end
