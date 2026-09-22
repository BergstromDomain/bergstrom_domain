class AddSupportFlagsToGuidePages < ActiveRecord::Migration[8.1]
  def change
    # Whether the feature a guide page documents is available to each
    # persona — Admin/SysAdmin are deliberately not tracked here, since
    # those personas get their own dedicated Admin-section guide pages
    # instead (see docs/context-prompts/active/Feature_-_User_Guide.md).
    add_column :guide_pages, :supports_guest,          :boolean, null: false, default: false
    add_column :guide_pages, :supports_user,            :boolean, null: false, default: false
    add_column :guide_pages, :supports_content_creator, :boolean, null: false, default: false
  end
end
