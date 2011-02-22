class DeleteDiscoveredAtFromPhotos < ActiveRecord::Migration
  def self.up
    remove_column :photos, :discovered_at
  end

  def self.down
    add_column :photos, :discovered_at, :datetime
  end
end
