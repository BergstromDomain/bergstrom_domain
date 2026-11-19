# app/services/dossier/timeline.rb

# Builds the Timeline: a user's Engagements newest first, each with its bench
# time (stretches no Assignment covers), and gaps between Engagements.
# Overlapping Engagements merge before looking for gaps, so a side job never
# shows as a gap. Only a permanent job has bench time: a contract runs from
# Assignment to Assignment, so one agency's contracts share an Engagement
# however far apart they are, except where another Engagement falls between
# two runs of its Assignments: there it splits into one card per run, and the
# rest of that space can be a gap. Personal Engagements (hobby projects) and
# career breaks never fill a gap nor split one. Ranges are inclusive dates; a
# month-precision end counts as the whole month, and a current one runs to today.
class Dossier::Timeline
  Period = Data.define(:from, :to) do
    def date_range = [ from, to ].map { |date| date.strftime("%b %Y") }.uniq.join(" – ")
    def duration   = Dossier::Timeline.duration(from, to)
  end

  # assignments: a split Engagement's card's Assignments (its run), in their
  # order; nil for a whole Engagement's card, which shows them all.
  Entry = Data.define(:kind, :engagement, :bench, :period, :assignments) do
    def date_range = period.date_range
    def duration   = period.duration
  end

  # The space between two cards of a split Engagement, and the Engagements in it.
  Others = Data.define(:period, :engagements) do
    def date_range = period.date_range
    def duration   = period.duration
  end

  DAYS_PER_MONTH = 365.25 / 12

  # Q-D11: under 1 year "N months", otherwise "N+ years" (floor).
  def self.duration(from, to) = duration_of(months(to - from + 1))

  def self.months(days) = (days / DAYS_PER_MONTH).round

  def self.duration_of(months)
    return "Under a month" if months < 1
    return "#{months} #{'month'.pluralize(months)}" if months < 12

    years = months / 12
    "#{years}+ #{'year'.pluralize(years)}"
  end

  # Merge overlapping or touching periods.
  def self.merge(periods)
    periods.sort_by(&:from).each_with_object([]) do |period, merged|
      if merged.any? && period.from <= merged.last.to + 1
        merged[-1] = Period.new(from: merged.last.from, to: [ merged.last.to, period.to ].max)
      else
        merged << period
      end
    end
  end

  # One Engagement's bench time, for its own page.
  def self.bench_for(engagement, today: Date.current)
    new(Dossier::Engagement.none, today: today).bench_for(engagement)
  end

  # Where a split Engagement's cards part, for its own page: the space and the
  # other Engagements in it.
  def self.other_engagements_for(engagement, today: Date.current)
    return [] if engagement.permanent? || engagement.personal? || engagement.career_break?

    # The others' dates are all it reads, not their Assignments.
    new(engagement.user.dossier_engagements.kept, today: today, preload: false).other_engagements_for(engagement)
  end

  # Assignments (in their hand-made order) with periods (bench, or Others)
  # among them: each period just above the first Assignment that ended before
  # it began, or else at the bottom, newest first.
  def self.interleave(assignments, periods)
    rows = assignments.dup
    periods.sort_by { |period| period_of(period).from }.each do |period|
      at = rows.index { |row| !period?(row) && row.effective_end && row.effective_end < period_of(period).from }
      at ? rows.insert(at, period) : rows.insert((rows.rindex { |row| !period?(row) } || -1) + 1, period)
    end
    rows
  end

  def self.period?(row) = row.is_a?(Period) || row.is_a?(Others)
  def self.period_of(row) = row.is_a?(Others) ? row.period : row
  private_class_method :period?, :period_of

  # preload: false for one Engagement's split spaces, which read only the
  # others' dates and types, and those only once a space is found.
  def initialize(engagements, today: Date.current, preload: true)
    # Only what the dates need: what a shown Engagement displays (its employer,
    # its Assignments' clients and logos) is the caller's to preload, as a
    # filtered Timeline hides some Engagements.
    @engagements = engagements.to_a
    @today = today
    return unless preload

    load_types
    # Bench time comes from a permanent job's Assignments, and a split from a
    # contract's; personal Engagements and career breaks have neither.
    ActiveRecord::Associations::Preloader.new(records: @engagements.select { |e| professional?(e) }, associations: :assignments).call
  end

  def entries
    engagement_entries = @engagements.flat_map do |engagement|
      cards_for(engagement).map do |card|
        Entry.new(kind: :engagement, engagement: engagement, bench: bench_for(engagement), period: card.period,
                  assignments: card.assignments)
      end
    end
    gap_entries = gaps.map { |gap| Entry.new(kind: :gap, engagement: nil, bench: [], period: gap, assignments: []) }

    # A career break with exactly a gap's dates shows above the gap.
    (engagement_entries + gap_entries).sort_by { |entry| [ entry.period.to, entry.period.from, entry.kind == :gap ? 0 : 1 ] }.reverse
  end

  def other_engagements_for(engagement)
    cards_for(engagement).each_cons(2).map do |before, after|
      space = Period.new(from: before.period.to + 1, to: after.period.from - 1)
      Others.new(period: space, engagements: others_in(engagement, space))
    end
  end

  # The bench or gap entry with exactly these dates (a bench knows its
  # Engagement), or nil.
  def period(from, to)
    candidates = entries.flat_map do |entry|
      next [ entry ] if entry.kind == :gap

      entry.bench.map { |bench| Entry.new(kind: :bench, engagement: entry.engagement, bench: [], period: bench, assignments: []) }
    end
    candidates.find { |entry| entry.period.from == from && entry.period.to == to }
  end

  def bench_for(engagement)
    return [] unless engagement.permanent?

    outer = period_for(engagement)
    covered = self.class.merge(engagement.assignments.map { |a| period_for(a) })
    edges = [ Period.new(from: outer.from, to: outer.from - 1) ] + covered + [ Period.new(from: outer.to + 1, to: outer.to) ]
    holes(edges)
  end

  private

  Card = Data.define(:period, :assignments)

  def professional?(engagement) = !engagement.personal? && !engagement.career_break?

  def period_for(dated)
    Period.new(from: dated.start_on, to: dated.effective_end || @today)
  end

  # Its cards, oldest first: one, unless it's a contract with another
  # professional Engagement between two runs of its Assignments.
  def cards_for(engagement)
    whole = [ Card.new(period: period_for(engagement), assignments: nil) ]
    return whole if engagement.permanent? || !professional?(engagement)

    groups = runs(engagement).slice_when do |(before, _), (after, _)|
      space = Period.new(from: before.to + 1, to: after.from - 1)
      space.from <= space.to && others_in(engagement, space).any?
    end.to_a
    return whole if groups.size < 2

    outer = whole.first.period
    groups.map.with_index do |group, index|
      from = index.zero? ? outer.from : group.first.first.from
      to   = index == groups.size - 1 ? outer.to : group.last.first.to
      members = group.flat_map(&:last)
      Card.new(period: Period.new(from: from, to: to), assignments: engagement.assignments.select { |a| members.include?(a) })
    end
  end

  # Its Assignments in runs of overlapping or touching ones, oldest first:
  # [[Period, [Assignment, …]], …], a run's Period covering them all.
  def runs(engagement)
    engagement.assignments.sort_by(&:start_on).each_with_object([]) do |assignment, runs|
      period = period_for(assignment)
      if runs.any? && period.from <= runs.last.first.to + 1
        last = runs.pop
        runs << [ Period.new(from: last.first.from, to: [ last.first.to, period.to ].max), last.last + [ assignment ] ]
      else
        runs << [ period, [ assignment ] ]
      end
    end
  end

  def load_types
    @types_loaded ||= ActiveRecord::Associations::Preloader.new(records: @engagements, associations: :employment_type).call
  end

  # The other professional Engagements overlapping a space, oldest first.
  def others_in(engagement, space)
    load_types
    @engagements.select do |other|
      next false if other == engagement || !professional?(other)

      period = period_for(other)
      period.from <= space.to && period.to >= space.from
    end.sort_by(&:start_on)
  end

  def gaps
    cards = @engagements.select { |e| professional?(e) }.flat_map { |e| cards_for(e).map(&:period) }
    holes(self.class.merge(cards))
  end

  # The stretches between consecutive merged periods.
  def holes(merged)
    merged.each_cons(2).filter_map do |before, after|
      Period.new(from: before.to + 1, to: after.from - 1) if after.from > before.to + 1
    end
  end
end
