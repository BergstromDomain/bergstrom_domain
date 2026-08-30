class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :blog_post, null: false, foreign_key: true
      t.references :user,      null: false, foreign_key: true
      t.references :parent,    foreign_key: { to_table: :comments }
      t.text       :body,      null: false

      t.timestamps
    end
  end
end
