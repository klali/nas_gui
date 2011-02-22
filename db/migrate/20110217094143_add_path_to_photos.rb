class AddPathToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :path, :string
    add_index :photos, :path, :unique => true
  end

  def self.down
    remove_index :photos, :path
    remove_column :photos, :path
  end
end
