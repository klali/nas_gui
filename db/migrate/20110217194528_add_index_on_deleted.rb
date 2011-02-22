class AddIndexOnDeleted < ActiveRecord::Migration
  def self.up
    add_index :photos, :deleted
  end

  def self.down
    remove_index :photos, :deleted
  end
end
