# app/services/dossier/seed_talks.rb

# One-off: Niklas's two All Things Testing Brisbane talks, as Contributions of
# the given user. A talk already there (same title, any case) is brought in
# line with the values below rather than added again, so running it twice
# changes nothing. "During" is the user's Engagement with the named
# employer, left empty if there's none. Skills are exactly those named; Skill
# names nobody has yet are added as Uncategorised, as typing them would. With
# poster_dir, each talk's poster is attached unless a file of that name
# already is.
class Dossier::SeedTalks
  EVENT = "All Things Testing Brisbane"

  TALKS = [
    { title: "Statistical Methods in Software Testing", start_on: Date.new(2023, 4, 19),
      location: "The Annex, Level 6, 12 Creek Street, Brisbane City", presented_as: "Technical test specialist",
      employer: "Plotlogic", poster: "Statistical.avif",
      skills: [ "Statistics", "Communication & Presentation", "Knowledge Sharing" ] },
    { title: "Getting Started with Robot Framework and Build Scalable Test Automation Solutions",
      start_on: Date.new(2024, 11, 19), location: "Gold Tower, Level 27, 10 Eagle St, Brisbane City",
      presented_as: "Test Manager, Elysium Digital", employer: "Elysium Digital", poster: "Robot.avif",
      skills: [ "Robot Framework", "Communication & Presentation", "Knowledge Sharing" ] }
  ].freeze

  attr_reader :notes

  def initialize(user, poster_dir: nil)
    @user = user
    @poster_dir = poster_dir && Pathname(poster_dir)
    @notes = []
  end

  def run!
    Dossier::Contribution.transaction { TALKS.each { |talk| seed(talk) } }
    self
  end

  private

  def seed(talk)
    contribution = @user.dossier_contributions.kept.find_by("LOWER(title) = ?", talk[:title].downcase) ||
                   @user.dossier_contributions.build
    added = contribution.new_record?
    contribution.assign_attributes(kind: "talk", title: talk[:title], event: event, start_on: talk[:start_on],
                                   start_precision: "day", location: talk[:location], presented_as: talk[:presented_as],
                                   engagement: engagement(talk[:employer]), skills_text: talk[:skills].join(", "),
                                   soft_skill_ids: [])
    contribution.validate
    changed = added || contribution.changed? || skills_changed?(contribution)
    contribution.save!
    poster = attach_poster(contribution, talk[:poster])
    @notes << "#{added ? 'Added' : (changed || poster ? 'Updated' : 'Unchanged')}: #{talk[:title]}"
  end

  def event
    @event ||= Dossier::Organisation.find_by("LOWER(name) = ?", EVENT.downcase) ||
               Dossier::Organisation.create!(name: EVENT).tap { @notes << "Added Organisation #{EVENT}" }
  end

  def engagement(employer)
    @user.dossier_engagements.kept.joins(:employer).find_by("LOWER(dossier_organisations.name) = ?", employer.downcase)
  end

  def skills_changed?(contribution)
    contribution.contribution_skills.any? { |link| link.new_record? || link.marked_for_destruction? }
  end

  # True when it attached the poster.
  def attach_poster(contribution, filename)
    path = @poster_dir&.join(filename)
    return false unless path&.file?
    return false if contribution.files.any? { |file| file.filename.to_s == filename }

    contribution.files.attach(io: path.open, filename: filename)
    true
  end
end
