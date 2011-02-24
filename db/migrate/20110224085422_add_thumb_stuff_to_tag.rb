class AddThumbStuffToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :thumb_id, :int
    add_column :tags, :thumb_width, :int
    add_column :tags, :thumb_height, :int
    add_column :tags, :thumb_x1, :int
    add_column :tags, :thumb_y1, :int
  end

  def self.down
    remove_column :tags, :thumb_y1
    remove_column :tags, :thumb_x1
    remove_column :tags, :thumb_height
    remove_column :tags, :thumb_width
    remove_column :tags, :thumb_id
  end
end
