class RenamePhotosToMedia < ActiveRecord::Migration
  def self.up
    rename_table :photos, :media
  end

  def self.down
    rename_table :media, :photos
  end
end
