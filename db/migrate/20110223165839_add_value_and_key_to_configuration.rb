class AddValueAndKeyToConfiguration < ActiveRecord::Migration
  def self.up
    add_column :configurations, :key, :string
    add_column :configurations, :value, :string
    remove_column :configurations, :path
    add_index :configurations, :key, :unique => true
  end

  def self.down
    remove_index :configurations, :key
    remove_column :configurations, :value
    remove_column :configurations, :key
    add_column :configurations, :path, :string
  end
end
