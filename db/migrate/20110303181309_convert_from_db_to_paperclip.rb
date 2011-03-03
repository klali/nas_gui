class ConvertFromDbToPaperclip < ActiveRecord::Migration
  def self.up
    drop_table :thumbnails
    drop_table :medium_images

    Photo.find_each do |photo|
      file = File.open(photo.path, 'rb')
      photo.image = file
      file.close
      photo.save
      puts photo.name
    end
    Tag.find_each do |tag|
      tag.generate_thumbnail
      tag.save
      puts tag.name
    end
  end

  def self.down
    create_table :thumbnails do |t|
      t.integer :photo_id
      t.integer :tag_id
      t.timestamps
    end
    add_column :thumbnails, :image, :blob
    create_table :medium_images do |t|
      t.integer :photo_id
      t.timestamps
    end
    add_column :medium_images, :image, :mediumblob
  end
end
