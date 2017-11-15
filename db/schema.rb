# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171104190321) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "apikeys", force: :cascade do |t|
    t.string   "key"
    t.boolean  "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gcps", force: :cascade do |t|
    t.integer  "map_id"
    t.float    "x"
    t.float    "y"
    t.decimal  "lat",        precision: 15, scale: 10
    t.decimal  "lon",        precision: 15, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "soft",                                 default: false
    t.string   "name"
  end

  add_index "gcps", ["soft"], name: "index_gcps_on_soft", using: :btree

  create_table "layer_properties", force: :cascade do |t|
    t.integer "layer_id"
    t.string  "name"
    t.text    "value"
    t.integer "level"
  end

  create_table "layers", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "is_visible",                                                      default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "maps_count",                                                      default: 0
    t.integer  "rectified_maps_count",                                            default: 0
    t.string   "bbox"
    t.geometry "bbox_geom",            limit: {:srid=>4326, :type=>"st_polygon"}
  end

  add_index "layers", ["bbox_geom"], name: "index_layers_on_bbox_geom", using: :gist

  create_table "map_layers", force: :cascade do |t|
    t.integer "map_id"
    t.integer "layer_id"
  end

  create_table "maps", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
    t.integer  "width"
    t.integer  "height"
    t.integer  "parent_id"
    t.integer  "status"
    t.integer  "mask_status"
    t.string   "bbox"
    t.geometry "bbox_geom",           limit: {:srid=>4326, :type=>"st_polygon"}
    t.decimal  "rough_lat",                                                      precision: 15, scale: 10
    t.decimal  "rough_lon",                                                      precision: 15, scale: 10
    t.geometry "rough_centroid",      limit: {:srid=>4326, :type=>"st_point"}
    t.integer  "rough_zoom"
    t.integer  "rough_state"
    t.datetime "rectified_at"
    t.datetime "gcp_touched_at"
    t.string   "transform_options",                                                                        default: "auto"
    t.string   "resample_options",                                                                         default: "cubic"
    t.string   "upload_file_name"
    t.string   "upload_content_type"
    t.integer  "upload_file_size"
    t.datetime "upload_updated_at"
  end

  add_index "maps", ["bbox_geom"], name: "index_maps_on_bbox_geom", using: :gist
  add_index "maps", ["rough_centroid"], name: "index_maps_on_rough_centroid", using: :gist

  create_table "my_maps", force: :cascade do |t|
    t.integer  "map_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "my_maps", ["map_id", "user_id"], name: "index_my_maps_on_map_id_and_user_id", unique: true, using: :btree
  add_index "my_maps", ["map_id"], name: "index_my_maps_on_map_id", using: :btree

  create_table "permissions", force: :cascade do |t|
    t.integer  "role_id",    null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",     default: true
    t.text     "description", default: ""
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.string   "ip"
    t.integer  "user_id"
    t.string   "user_agent"
    t.integer  "transaction_id"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree

end
