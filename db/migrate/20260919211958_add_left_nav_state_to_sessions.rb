class AddLeftNavStateToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :left_nav_visible, :boolean, default: true, null: false
    add_column :sessions, :left_nav_section, :string
    add_column :sessions, :collapsed_nav_sections, :string, array: true, default: [], null: false
  end
end
