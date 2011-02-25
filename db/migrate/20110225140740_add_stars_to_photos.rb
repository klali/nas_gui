class AddStarsToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :stars, :float
  end

  def self.down
    remove_column :photos, :stars
  end
end
