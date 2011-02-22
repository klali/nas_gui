class AddDeletedToPhoto < ActiveRecord::Migration
  def self.up
    add_column :photos, :deleted, :boolean, :default => false
    execute "update photos set deleted = false"
  end

  def self.down
    remove_column :photos, :deleted
  end
end
