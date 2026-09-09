class CreateSocialMediaPlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :social_media_platforms do |t|
      t.string :name, null: false
      t.string :url,  null: false
      t.text   :description
      t.string :slug

      t.timestamps
    end

    add_index :social_media_platforms, :name, unique: true
    add_index :social_media_platforms, :slug, unique: true
  end
end
