class RemovePhotosIndexOnDeleted < ActiveRecord::Migration
  def self.up
    remove_index :photos, :deleted
  end

  def self.down
    add_index :photos, :deleted
  end
end
