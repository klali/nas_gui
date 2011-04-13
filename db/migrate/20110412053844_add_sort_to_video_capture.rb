class AddSortToVideoCapture < ActiveRecord::Migration
  def self.up
    add_column :video_captures, :sort, :int
  end

  def self.down
    remove_column :video_captures, :sort
  end
end
