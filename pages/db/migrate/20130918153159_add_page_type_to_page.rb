class AddPageTypeToPage < ActiveRecord::Migration
  def change
    add_column :refinery_pages, :page_type, :string, null: false, default: 'WebPage'
  end
end
