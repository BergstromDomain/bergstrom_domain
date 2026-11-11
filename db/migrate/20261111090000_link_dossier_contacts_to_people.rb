# db/migrate/20261111090000_link_dossier_contacts_to_people.rb

# An Assignment's Colleagues and a Vendor's or Customer's Staff become links to
# People (Occasions), who hold the name, Work Email and LinkedIn; the link
# keeps only what belongs to that Assignment: position and comment. Mobile
# numbers are dropped. Each contact is linked to the Person of the same full
# name (any case), or to a new Restricted Person owned by the Assignment's
# owner. Self-contained (no app models), so later model changes can't break it.
class LinkDossierContactsToPeople < ActiveRecord::Migration[8.1]
  TABLES = {
    dossier_colleagues: "JOIN dossier_assignments a ON a.id = c.assignment_id",
    dossier_staff_members: "JOIN dossier_assignment_partners p ON p.id = c.assignment_partner_id " \
                           "JOIN dossier_assignments a ON a.id = p.assignment_id"
  }.freeze
  LINKEDIN_PROFILE = %r{linkedin\.com/in/([^/?#]+)}i

  def up
    add_column :people, :work_email, :string
    TABLES.each_key { |table| add_reference table, :person, foreign_key: true }
    TABLES.each { |table, join| link_people(table, join) }
    TABLES.each_key do |table|
      change_column_null table, :person_id, false
      remove_column table, :name
      remove_column table, :mobile
      remove_column table, :email
      remove_column table, :linkedin_url
    end
  end

  def down
    TABLES.each_key do |table|
      add_column table, :name, :string
      add_column table, :mobile, :string
      add_column table, :email, :string
      add_column table, :linkedin_url, :string
      execute <<~SQL.squish
        UPDATE #{table} c SET name = CONCAT_WS(' ', NULLIF(pe.first_name, ''), NULLIF(pe.middle_name, ''), NULLIF(pe.last_name, '')),
          email = pe.work_email FROM people pe WHERE pe.id = c.person_id
      SQL
      change_column_null table, :name, false
      remove_reference table, :person, foreign_key: true
    end
    remove_column :people, :work_email
  end

  private

  def link_people(table, join)
    select_all("SELECT c.id, c.name, c.email, c.linkedin_url, a.user_id FROM #{table} c #{join}").each do |row|
      person_id = find_person(row["name"]) || create_person(row["name"], row["user_id"])
      execute "UPDATE #{table} SET person_id = #{person_id.to_i} WHERE id = #{row['id'].to_i}"
      if row["email"].present?
        execute "UPDATE people SET work_email = #{quote(row['email'])} WHERE id = #{person_id.to_i} AND work_email IS NULL"
      end
      add_linkedin(person_id, row["linkedin_url"]) if row["linkedin_url"].present?
    end
  end

  def find_person(name)
    select_all("SELECT id, first_name, middle_name, last_name FROM people").find do |person|
      person.values_at("first_name", "middle_name", "last_name").compact_blank.join(" ").casecmp?(name.squish)
    end&.fetch("id")
  end

  def create_person(name, user_id)
    *first, last = name.squish.split
    first, last = [ last ], nil if first.empty?
    full_name = [ *first, last ].compact.join(" ")
    slug = full_name.parameterize
    slug = "#{slug}-#{SecureRandom.uuid}" if select_value("SELECT 1 FROM people WHERE slug = #{quote(slug)}")
    select_value(<<~SQL.squish)
      INSERT INTO people (first_name, last_name, user_id, classification, slug, created_at, updated_at)
      VALUES (#{quote(first.join(' '))}, #{quote(last)}, #{user_id.to_i}, 'restricted', #{quote(slug)}, NOW(), NOW())
      RETURNING id
    SQL
  end

  # As the Person's LinkedIn account (its username, or the URL when it isn't
  # a /in/ profile), unless they have one.
  def add_linkedin(person_id, url)
    platform_id = select_value("SELECT id FROM social_media_platforms WHERE LOWER(name) = 'linkedin'") ||
                  select_value(<<~SQL.squish)
                    INSERT INTO social_media_platforms (name, url, slug, created_at, updated_at)
                    VALUES ('LinkedIn', 'https://www.linkedin.com/', 'linkedin', NOW(), NOW()) RETURNING id
                  SQL
    return if select_value("SELECT 1 FROM person_social_media_accounts WHERE person_id = #{person_id.to_i} " \
                           "AND social_media_platform_id = #{platform_id.to_i}")

    username = url[LINKEDIN_PROFILE, 1] || url
    execute <<~SQL.squish
      INSERT INTO person_social_media_accounts (person_id, social_media_platform_id, username, created_at, updated_at)
      VALUES (#{person_id.to_i}, #{platform_id.to_i}, #{quote(username)}, NOW(), NOW())
    SQL
  end
end
