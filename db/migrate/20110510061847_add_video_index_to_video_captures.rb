class AddVideoIndexToVideoCaptures < ActiveRecord::Migration
  def self.up
    add_index :video_captures, :video_id
  end

  def self.down
    remove_index :video_captures, :video_id
  end
end
