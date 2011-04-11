class RenamePhotosTagsToMediasTags < ActiveRecord::Migration
  def self.up
    rename_table :photos_tags, :media_tags
    rename_column :media_tags, :photo_id, :media_id
  end

  def self.down
    rename_table :media_tags, :photos_tags
    rename_column :photos_tags, :media_id, :photo_id
  end
end
