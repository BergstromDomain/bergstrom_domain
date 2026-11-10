# app/services/dossier/skill_taxonomy.rb

# Applies a Skill taxonomy (db/seeds/dossier/skill_taxonomy.yml, parsed) to the
# shared Skills and Skill Categories, in one transaction, returning what it
# changed as lines of text. Safe to run again: a second run changes nothing.
#
#   vendors:            [{ name, abbreviation }] — found by name or abbreviation, else created
#   categories:         [{ name, was: [old names], description, subcategories: [{ name, was, description }] }],
#                       numbered in the order listed (their position)
#   merge:              [{ into, from: [names] }] — Skill#merge_into!, before the Skills below
#   skills:             [{ name, find: [old names], category: "Top › Sub", aliases, remove_aliases,
#                          vendor, show_vendor, version_of, description }]
#   split:              [{ from, into: [names] }] — every new Skill gets all its links, then it's deleted
#   delete_skills:      [names] — only when unused
#   delete_categories:  [paths] — only when empty
#
# A Skill or category it doesn't mention is left alone. Descriptions only fill
# blanks; aliases are added (and remove_aliases removed), never replaced.
class Dossier::SkillTaxonomy
  class Error < StandardError; end

  SEPARATOR = " › "

  # "Protocols & Standards › VoIP" (or a top-level name), ignoring case.
  def self.find_category(path)
    top_name, sub_name = path.to_s.split(SEPARATOR, 2).map(&:strip)
    top = Dossier::SkillCategory.top_level.find_by("LOWER(name) = ?", top_name.to_s.downcase)
    return top unless top && sub_name

    top.subcategories.find_by("LOWER(name) = ?", sub_name.downcase)
  end

  def initialize(taxonomy)
    @taxonomy = taxonomy
    @report = []
  end

  # With dry_run, reports the same changes but rolls them back.
  def apply!(dry_run: false)
    ActiveRecord::Base.transaction do
      list("vendors").each { |row| vendor(row) }
      list("categories").each.with_index(1) { |row, position| category(row, parent: nil, position: position) }
      list("merge").each { |row| merge(row) }
      list("skills").each { |row| skill(row) }
      list("split").each { |row| split(row) }
      list("delete_skills").each { |name| delete_skill(name) }
      list("delete_categories").each { |path| delete_category(path) }
      raise ActiveRecord::Rollback if dry_run
    end
    @report
  end

  private

  def list(key) = Array(@taxonomy[key])

  def note(line) = @report << line

  # ── Vendors ───────────────────────────────────────────────────────────────
  def vendor(row)
    return if find_vendor(row["name"])

    Dossier::Organisation.create!(name: row["name"], abbreviation: row["abbreviation"])
    note("Created vendor #{row['name']}")
  end

  def find_vendor(name)
    Dossier::Organisation.find_by("LOWER(name) = :n OR LOWER(abbreviation) = :n", n: name.to_s.downcase)
  end

  # ── Categories ────────────────────────────────────────────────────────────
  def category(row, parent:, position:)
    path = [ parent&.name, row["name"] ].compact.join(SEPARATOR)
    record = self.class.find_category(path) || old_category(row) || Dossier::SkillCategory.new
    created = record.new_record?
    record.assign_attributes(name: row["name"], parent: parent, position: position)
    record.description = row["description"] if record.description.blank? && row["description"].present?
    save!(record, path)
    note(created ? "Created Skill Category #{path}" : "Updated Skill Category #{path}") if changed?(record, created)
    Array(row["subcategories"]).each.with_index(1) { |sub, index| category(sub, parent: record, position: index) }
  end

  def old_category(row)
    names = Array(row["was"]).map(&:downcase)
    Dossier::SkillCategory.where("LOWER(name) IN (?)", names).first if names.any?
  end

  def category!(path, row_name)
    self.class.find_category(path) || raise(Error, "#{row_name}: no Skill Category \"#{path}\"")
  end

  # ── Skills ────────────────────────────────────────────────────────────────
  def merge(row)
    into = find_skill(row["into"])
    Array(row["from"]).each do |name|
      from = find_skill(name)
      next if from.nil? || from == into
      raise Error, "Merge: no Skill \"#{row['into']}\" to merge #{name} into" unless into

      from.merge_into!(into)
      note("Merged #{name} into #{into.name}")
    end
  end

  def skill(row)
    record = [ row["name"], *Array(row["find"]) ].lazy.filter_map { |name| find_skill(name) }.first ||
             Dossier::Skill.new
    created = record.new_record?
    record.assign_attributes(skill_attributes(record, row))
    save!(record, row["name"])
    note(created ? "Created Skill #{record.name}" : "Updated Skill #{record.name}") if changed?(record, created)
  end

  def skill_attributes(record, row)
    removed = Array(row["remove_aliases"]).map(&:downcase)
    aliases = (record.aliases + Array(row["aliases"])).uniq(&:downcase).reject { |a| removed.include?(a.downcase) }
    attributes = { name: row["name"], skill_category: category!(row["category"], row["name"]), aliases: aliases }
    attributes[:vendor] = row["vendor"] && (find_vendor(row["vendor"]) || raise(Error, "#{row['name']}: no vendor \"#{row['vendor']}\"")) if row.key?("vendor")
    attributes[:show_vendor_in_name] = row["show_vendor"] if row.key?("show_vendor")
    attributes[:parent] = version_of(row) if row.key?("version_of")
    attributes[:description] = row["description"] if record.description.blank? && row["description"].present?
    attributes
  end

  def version_of(row)
    row["version_of"] && (find_skill(row["version_of"]) || raise(Error, "#{row['name']}: no Skill \"#{row['version_of']}\" to be a version of"))
  end

  def split(row)
    from = find_skill(row["from"])
    return unless from

    targets = Array(row["into"]).map { |name| find_skill(name) || raise(Error, "Split: no Skill \"#{name}\" to split #{row['from']} into") }
    targets.each { |target| copy_links(from, target) }
    [ from.assignment_skills, from.achievement_skills, from.credential_skills ].each(&:destroy_all)
    from.reload.destroy!
    note("Split #{row['from']} into #{targets.map(&:name).join(', ')}")
  end

  def copy_links(from, target)
    from.assignment_skills.each { |link| target.assignment_skills.find_or_create_by!(assignment_id: link.assignment_id, stack_slot: link.stack_slot) }
    from.achievement_skills.each { |link| target.achievement_skills.find_or_create_by!(achievement_id: link.achievement_id) }
    from.credential_skills.each { |link| target.credential_skills.find_or_create_by!(credential_id: link.credential_id) }
  end

  def delete_skill(name)
    record = Dossier::Skill.find_by("LOWER(name) = ?", name.downcase)
    return unless record

    if record.assignment_skills.exists? || record.achievement_skills.exists? || record.credential_skills.exists?
      note("Kept Skill #{name}: still used")
    else
      record.destroy!
      note("Deleted Skill #{name}")
    end
  end

  def delete_category(path)
    record = self.class.find_category(path)
    return unless record

    if record.destroy
      note("Deleted Skill Category #{path}")
    else
      note("Kept Skill Category #{path}: it still has #{record.subcategories.exists? ? 'sub-categories' : 'Skills'}")
    end
  end

  def find_skill(name) = name.present? ? Dossier::Skill.find_by_name_or_alias(name) : nil

  # ── Shared ────────────────────────────────────────────────────────────────
  def save!(record, label)
    record.save!
  rescue ActiveRecord::RecordInvalid => e
    raise Error, "#{label}: #{e.record.errors.full_messages.to_sentence}"
  end

  def changed?(record, created) = created || record.saved_changes.except("updated_at").any?
end
