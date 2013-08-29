class CreateRefinerycmsResourcesSchema < ActiveRecord::Migration
  def change
    create_table :refinery_resources do |t|
      t.string   :file_mime_type, null: false
      t.string   :file_name, null: false
      t.integer  :file_size, null: false
      t.string   :file_uid,  null: false

      t.timestamps null: false
    end

    add_index :refinery_resources, :file_name, unique: true
    add_index :refinery_resources, :updated_at

  end
end
