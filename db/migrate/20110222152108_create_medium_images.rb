class CreateMediumImages < ActiveRecord::Migration
  def self.up
    create_table :medium_images do |t|
      t.integer :photo_id

      t.timestamps
    end
    add_column :medium_images, :image, :mediumblob
    remove_column :photos, :medium_image
  end

  def self.down
    drop_table :medium_images
    add_column :photos, :medium_image, :mediumblob
  end
end
