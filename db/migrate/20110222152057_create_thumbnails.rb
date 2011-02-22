class CreateThumbnails < ActiveRecord::Migration
  def self.up
    create_table :thumbnails do |t|
      t.integer :photo_id

      t.timestamps
    end
    add_column :thumbnails, :image, :blob
    remove_column :photos, :thumbnail
  end

  def self.down
    drop_table :thumbnails
    add_column :photos, :thumbnail, :blob
  end
end
