class CreatePersonSocialMediaAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :person_social_media_accounts do |t|
      t.references :person,                null: false, foreign_key: true
      t.references :social_media_platform, null: false, foreign_key: true
      t.string     :username,              null: false

      t.timestamps
    end

    add_index :person_social_media_accounts, %i[person_id social_media_platform_id],
      unique: true, name: "index_person_social_media_accounts_on_person_and_platform"
  end
end
