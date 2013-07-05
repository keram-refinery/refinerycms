class CreateRefinerycmsImagesSchema < ActiveRecord::Migration
  def change
    create_table :refinery_images do |t|
      t.string   :image_mime_type, :null => false, :limit => 64
      t.string   :image_name, :null => false
      t.integer  :image_size, :null => false
      t.integer  :image_width, :null => false
      t.integer  :image_height, :null => false
      t.string   :image_uid, :null => false

      t.timestamps
    end

    add_index :refinery_images, :image_name, :unique => true
    add_index :refinery_images, :updated_at

  end
end
