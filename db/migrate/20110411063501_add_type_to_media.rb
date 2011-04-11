class AddTypeToMedia < ActiveRecord::Migration
  def self.up
    add_column :media, :type, :string
  end

  def self.down
    remove_column :media, :type
  end
end
