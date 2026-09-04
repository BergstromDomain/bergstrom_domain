class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :blog_post, null: false, foreign_key: true
      t.references :user,      null: false, foreign_key: true
      t.string     :face,      null: false, default: "neutral"

      t.timestamps
    end

    add_index :likes, [ :blog_post_id, :user_id ], unique: true
  end
end
