# app/services/dossier/skill_names.rb

# Turns typed Skill lists ("Jira, Windows (XP, Vista)") into Skills, for a
# Tech Stack, an Achievement or a Training course. Commas split only outside
# brackets. Each name is matched by name or alias; "Name (a, b)" that isn't a
# Skill itself means versions a and b of Name: an existing version of it by
# its label, else "Name a" by name or alias, else a new Uncategorised Skill
# "Name a" that is a version of Name. Unknown names become new Uncategorised
# Skills, one per name however often it's typed.
class Dossier::SkillNames
  VERSIONS = /\A(?<name>[^()]+?)\s*\((?<versions>[^()]+)\)\z/

  def initialize
    @new_skills = {}
  end

  def skills(text)
    split(text).flat_map { |name| resolve(name) }.uniq
  end

  private

  def split(text)
    depth = 0
    text.to_s.each_char.with_object([ +"" ]) do |char, names|
      depth += 1 if char == "("
      depth -= 1 if char == ")" && depth.positive?
      char == "," && depth.zero? ? names << +"" : names.last << char
    end.map(&:strip).compact_blank.uniq(&:downcase)
  end

  def resolve(name)
    existing = Dossier::Skill.find_by_name_or_alias(name)
    return [ existing ] if existing

    match = VERSIONS.match(name)
    return [ find_or_build(name) ] unless match

    parent = find_or_build(match[:name].strip)
    match[:versions].split(",").map(&:strip).compact_blank.uniq(&:downcase).map { |label| version(parent, label) }
  end

  def version(parent, label)
    full_name = "#{parent.name} #{label}"
    known = parent.persisted? && parent.versions.find { |skill| skill.version_label.casecmp?(label) }
    known || Dossier::Skill.find_by_name_or_alias(full_name) ||
      find_or_build(full_name, parent: (parent unless parent.parent_id))
  end

  def find_or_build(name, parent: nil)
    @new_skills[name.downcase] ||= Dossier::Skill.find_by_name_or_alias(name) ||
                                   Dossier::Skill.new_uncategorised(name).tap { |skill| skill.parent = parent }
  end
end
