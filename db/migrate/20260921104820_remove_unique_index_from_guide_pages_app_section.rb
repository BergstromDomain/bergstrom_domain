class RemoveUniqueIndexFromGuidePagesAppSection < ActiveRecord::Migration[8.1]
  def change
    # app_section is a grouping/category field, not a 1-page-per-app slot —
    # many guide pages can share a section (e.g. "Classification" and
    # "Sign Up" both under :core), each distinguished by its own title.
    remove_index :guide_pages, :app_section
    add_index    :guide_pages, :app_section
  end
end
