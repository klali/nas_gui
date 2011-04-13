class AddVideIdToVideoCaptures < ActiveRecord::Migration
  def self.up
    add_column :video_captures, :video_id, :int
  end

  def self.down
    remove_column :video_captures, :video_id
  end
end
