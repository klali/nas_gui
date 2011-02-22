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

ActiveRecord::Schema.define(:version => 20110222153950) do

  create_table "configurations", :force => true do |t|
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "medium_images", :force => true do |t|
    t.integer  "photo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "image",      :limit => 16777215
  end

  add_index "medium_images", ["photo_id"], :name => "index_medium_images_on_photo_id", :unique => true

  create_table "photos", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path"
    t.boolean  "deleted",    :default => false
    t.datetime "taken_at"
  end

  add_index "photos", ["deleted"], :name => "index_photos_on_deleted"
  add_index "photos", ["path"], :name => "index_photos_on_path", :unique => true

  create_table "photos_tags", :id => false, :force => true do |t|
    t.integer "photo_id"
    t.integer "tag_id"
  end

  add_index "photos_tags", ["photo_id", "tag_id"], :name => "index_photos_tags_on_photo_id_and_tag_id", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "thumbnail"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "thumbnails", :force => true do |t|
    t.integer  "photo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "image"
  end

  add_index "thumbnails", ["photo_id"], :name => "index_thumbnails_on_photo_id", :unique => true

end
