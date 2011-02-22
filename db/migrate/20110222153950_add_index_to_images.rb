class AddIndexToImages < ActiveRecord::Migration
  def self.up
    add_index :thumbnails, :photo_id, :unique => true
    add_index :medium_images, :photo_id, :unique => true
  end

  def self.down
    remove_index :thumbnails, :photo_id
    remove_index :medium_images, :photo_id
  end
end
