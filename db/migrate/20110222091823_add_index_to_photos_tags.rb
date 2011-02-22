class AddIndexToPhotosTags < ActiveRecord::Migration
  def self.up
    add_index :photos_tags, [:photo_id, :tag_id], :unique => true
  end

  def self.down
    remove_index :photos_tags, [:photo_id, :tag_id]
  end
end
