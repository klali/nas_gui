class AddNestedSetToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :parent_id, :integer
    add_column :tags, :lft, :integer
    add_column :tags, :rgt, :integer
  end

  def self.down
    remove_column :tags, :rgt
    remove_column :tags, :lft
    remove_column :tags, :parent_id
  end
end
