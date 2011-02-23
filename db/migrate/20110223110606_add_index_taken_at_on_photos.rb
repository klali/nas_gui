class AddIndexTakenAtOnPhotos < ActiveRecord::Migration
  def self.up
    add_index :photos, :taken_at
  end

  def self.down
    remove_index :photos, :taken_at
  end
end
