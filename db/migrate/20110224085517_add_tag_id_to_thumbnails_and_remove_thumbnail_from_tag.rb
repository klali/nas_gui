class AddTagIdToThumbnailsAndRemoveThumbnailFromTag < ActiveRecord::Migration
  def self.up
    add_column :thumbnails, :tag_id, :int
    remove_column :tags, :thumbnail
    add_index :thumbnails, :tag_id, :unique => true
  end

  def self.down
    remove_index :thumbnails, :tag_id
    remove_column :thumbnails, :tag_id
    add_column :tags, :thumbnail, :blob
  end
end
