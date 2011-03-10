# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110310085706) do

  create_table "configurations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.string   "value"
  end

  add_index "configurations", ["key"], :name => "index_configurations_on_key", :unique => true

  create_table "photos", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path"
    t.boolean  "deleted",            :default => false
    t.datetime "taken_at"
    t.float    "stars"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "width"
    t.integer  "height"
    t.integer  "medium_width"
    t.integer  "medium_height"
    t.integer  "thumb_width"
    t.integer  "thumb_height"
    t.integer  "medium_size"
    t.integer  "thumb_size"
  end

  add_index "photos", ["path"], :name => "index_photos_on_path", :unique => true
  add_index "photos", ["taken_at"], :name => "index_photos_on_taken_at"

  create_table "photos_tags", :id => false, :force => true do |t|
    t.integer "photo_id"
    t.integer "tag_id"
  end

  add_index "photos_tags", ["photo_id", "tag_id"], :name => "index_photos_tags_on_photo_id_and_tag_id", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "thumb_id"
    t.integer  "thumb_width"
    t.integer  "thumb_height"
    t.integer  "thumb_x1"
    t.integer  "thumb_y1"
    t.string   "thumbnail_file_name"
    t.string   "thumbnail_content_type"
    t.integer  "thumbnail_file_size"
    t.datetime "thumbnail_updated_at"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

end
