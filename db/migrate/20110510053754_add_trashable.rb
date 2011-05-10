class AddTrashable < ActiveRecord::Migration
  def self.up
    ActsAsTrashable::TrashRecord.create_table
    execute "delete from media where deleted = true"
    remove_column :media, :deleted
  end

  def self.down
    drop_table :trash_records
    add_column :media, :deleted, :boolean
  end
end
