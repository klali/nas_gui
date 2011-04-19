class AddDurationToMedia < ActiveRecord::Migration
  def self.up
    add_column :media, :duration, :time
  end

  def self.down
    remove_column :media, :duration
  end
end
