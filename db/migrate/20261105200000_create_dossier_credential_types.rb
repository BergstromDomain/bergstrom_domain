# db/migrate/20261105200000_create_dossier_credential_types.rb

# Dossier Block 5a — Credential Type becomes reference data (Q-D9), replacing
# the string credential_type that Block 4.5's Training started with. Existing
# rows were all "course", so they move to a Course type (training: true).
# Credentials also gain an expiry (day or month precision), a certificate
# number ("Credential ID") and a verification URL.
class CreateDossierCredentialTypes < ActiveRecord::Migration[8.1]
  def up
    create_table :dossier_credential_types do |t|
      t.string  :name,        null: false
      t.text    :description
      t.integer :position,    null: false, default: 0
      t.boolean :training,    null: false, default: false
      t.string  :slug
      t.timestamps
    end
    add_index :dossier_credential_types, "LOWER(name)", unique: true, name: "index_dossier_credential_types_on_lower_name"
    add_index :dossier_credential_types, :slug, unique: true

    add_reference :dossier_credentials, :credential_type, foreign_key: { to_table: :dossier_credential_types }
    execute <<~SQL
      INSERT INTO dossier_credential_types (name, position, training, slug, created_at, updated_at)
      SELECT 'Course', 4, TRUE, 'course', NOW(), NOW()
      WHERE EXISTS (SELECT 1 FROM dossier_credentials);

      UPDATE dossier_credentials
      SET credential_type_id = (SELECT id FROM dossier_credential_types WHERE slug = 'course');
    SQL
    change_column_null :dossier_credentials, :credential_type_id, false
    remove_column :dossier_credentials, :credential_type

    add_column :dossier_credentials, :expires_on,         :date
    add_column :dossier_credentials, :expires_precision,  :string, null: false, default: "month"
    add_column :dossier_credentials, :certificate_number, :string
    add_column :dossier_credentials, :verification_url,   :string
  end

  def down
    remove_column :dossier_credentials, :verification_url
    remove_column :dossier_credentials, :certificate_number
    remove_column :dossier_credentials, :expires_precision
    remove_column :dossier_credentials, :expires_on
    add_column :dossier_credentials, :credential_type, :string, null: false, default: "course"
    remove_reference :dossier_credentials, :credential_type, foreign_key: { to_table: :dossier_credential_types }
    drop_table :dossier_credential_types
  end
end
