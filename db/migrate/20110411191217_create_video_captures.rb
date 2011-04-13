class CreateVideoCaptures < ActiveRecord::Migration
  def self.up
    create_table :video_captures do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :video_captures
  end
end
