class AddAttachmentThumbnailToTag < ActiveRecord::Migration
  def self.up
    add_column :tags, :thumbnail_file_name, :string
    add_column :tags, :thumbnail_content_type, :string
    add_column :tags, :thumbnail_file_size, :integer
    add_column :tags, :thumbnail_updated_at, :datetime
  end

  def self.down
    remove_column :tags, :thumbnail_file_name
    remove_column :tags, :thumbnail_content_type
    remove_column :tags, :thumbnail_file_size
    remove_column :tags, :thumbnail_updated_at
  end
end
