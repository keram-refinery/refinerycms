class CreateRefinerycmsImagesSchema < ActiveRecord::Migration
  def change
    create_table :refinery_images do |t|
      t.string   :image_mime_type, null: false
      t.string   :image_name,     null: false
      t.integer  :image_size,     null: false
      t.integer  :image_width,    null: false
      t.integer  :image_height,   null: false
      t.string   :image_uid,      null: false

      t.timestamps null: false
    end

    add_index :refinery_images, :image_name, unique: true
    add_index :refinery_images, :updated_at

    Refinery::Image.create_translation_table!({
      alt: :string,
      caption: :string
    })
  end
end
