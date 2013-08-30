class CreateRefinerycmsPagesSchema < ActiveRecord::Migration
  def up
    create_table :refinery_page_parts do |t|
      t.references :page, null: false
      t.string   :title,  null: false
      t.integer  :position, null: false, default: 0
      t.boolean  :active,   null: false, default: true

      t.timestamps null: false
    end

    add_index :refinery_page_parts, [:page_id, :title], unique: true

    create_table :refinery_pages do |t|
      t.integer :parent_id
      t.string  :slug
      t.boolean :show_in_menu, default: true
      t.string  :link_url
      t.boolean :deletable, null: false, default: true
      t.boolean :draft,     null: false, default: false
      t.boolean :skip_to_first_child, null: false, default: false
      t.integer :lft,       null: false
      t.integer :rgt,       null: false
      t.integer :depth,     null: false, default: 0
      t.string  :plugin_page_id

      t.timestamps null: false
    end

    add_index :refinery_pages, [:lft, :rgt]
    add_index :refinery_pages, [:rgt]
    add_index :refinery_pages, [:draft, :show_in_menu, :lft, :rgt]
    add_index :refinery_pages, :parent_id
    add_index :refinery_pages, :updated_at

    Refinery::PagePart.create_translation_table!({
      body: :text
    })

    # because of:
    # SQLite3::SQLException: Cannot add a NOT NULL column with default value NULL:
    # ALTER TABLE "refinery_page_translations" ADD "title" varchar(255) NOT NUL ..
    #
    # which is bug in globalize3, until it will be fixed as workaround
    # we set default value to ''
    Refinery::Page.create_translation_table!({
      title: { type: :string, null: false, default: '' },
      slug: { type: :string, null: false, default: '' },
      custom_slug: :string
    })

    add_index :refinery_page_translations, :title
    add_index :refinery_page_translations, :slug
  end

  def down
    drop_table :refinery_page_parts
    drop_table :refinery_pages
    Refinery::PagePart.drop_translation_table!
    Refinery::Page.drop_translation_table!
  end
end
