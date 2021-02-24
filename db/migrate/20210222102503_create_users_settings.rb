class CreateUsersSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :users_settings do |t|
      t.integer :user_id, null: false
      t.string "config_font", default: "default"
      t.string "config_navbar", default: "default", null: false
      t.string "config_theme", default: "default"
      t.boolean "display_announcements", default: true
      t.boolean "display_sponsors", default: true
      t.string "editor_version", default: "v1"
      t.integer "experience_level"
      t.boolean "feed_mark_canonical", default: false
      t.boolean "feed_referential_link", default: true, null: false
      t.string "feed_url"
      t.string "inbox_guidelines"
      t.string "inbox_type", default: "private"
      t.boolean "permit_adjacent_sponsors", default: true
      t.string "brand_color1", default: "#000000"
      t.string "brand_color2", default: "#ffffff"
      t.boolean "display_email_on_profile", default: false

      t.timestamps
    end
  end
end
