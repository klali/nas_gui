class AddThumbnailToPhoto < ActiveRecord::Migration
  def self.up
    add_column :photos, :thumbnail, :blob
  end

  def self.down
    remove_column :photos, :thumbnail
  end
end
