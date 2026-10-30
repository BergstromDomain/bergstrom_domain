# app/services/dossier/timeline.rb

# Builds the Timeline: a user's Engagements newest first, each with its bench
# time (stretches no Assignment covers), and gaps between Engagements.
# Overlapping Engagements merge before looking for gaps, so a side job never
# shows as a gap. Ranges are inclusive dates; a month-precision end counts as
# the whole month, and a current one runs to today.
class Dossier::Timeline
  Period = Data.define(:from, :to) do
    def date_range = "#{from.strftime('%b %Y')} – #{to.strftime('%b %Y')}"
    def duration   = Dossier::Timeline.duration(from, to)
  end

  Entry = Data.define(:kind, :engagement, :bench, :period) do
    def date_range = period.date_range
    def duration   = period.duration
  end

  DAYS_PER_MONTH = 365.25 / 12

  # Q-D11: under 1 year "N months", otherwise "N+ years" (floor).
  def self.duration(from, to)
    months = ((to - from + 1) / DAYS_PER_MONTH).round
    return "Under a month" if months < 1
    return "#{months} #{'month'.pluralize(months)}" if months < 12

    years = months / 12
    "#{years}+ #{'year'.pluralize(years)}"
  end

  def initialize(engagements, today: Date.current)
    # Rows show "Client - Project", so Roles aren't loaded.
    @engagements = engagements.includes(:employment_type, assignments: :client).to_a
    @today = today
  end

  def entries
    engagement_entries = @engagements.map do |engagement|
      Entry.new(kind: :engagement, engagement: engagement, bench: bench_for(engagement), period: period_for(engagement))
    end
    gap_entries = gaps.map { |gap| Entry.new(kind: :gap, engagement: nil, bench: [], period: gap) }

    (engagement_entries + gap_entries).sort_by { |entry| [ entry.period.to, entry.period.from ] }.reverse
  end

  # The bench or gap entry with exactly these dates (a bench knows its
  # Engagement), or nil.
  def period(from, to)
    candidates = entries.flat_map do |entry|
      next [ entry ] if entry.kind == :gap

      entry.bench.map { |bench| Entry.new(kind: :bench, engagement: entry.engagement, bench: [], period: bench) }
    end
    candidates.find { |entry| entry.period.from == from && entry.period.to == to }
  end

  private

  def period_for(dated)
    Period.new(from: dated.start_on, to: dated.effective_end || @today)
  end

  def gaps
    holes(merge(@engagements.map { |e| period_for(e) }))
  end

  def bench_for(engagement)
    outer = period_for(engagement)
    covered = merge(engagement.assignments.map { |a| period_for(a) })
    edges = [ Period.new(from: outer.from, to: outer.from - 1) ] + covered + [ Period.new(from: outer.to + 1, to: outer.to) ]
    holes(edges)
  end

  # Merge overlapping or touching periods (sorted by start).
  def merge(periods)
    periods.sort_by(&:from).each_with_object([]) do |period, merged|
      if merged.any? && period.from <= merged.last.to + 1
        merged[-1] = Period.new(from: merged.last.from, to: [ merged.last.to, period.to ].max)
      else
        merged << period
      end
    end
  end

  # The stretches between consecutive merged periods.
  def holes(merged)
    merged.each_cons(2).filter_map do |before, after|
      Period.new(from: before.to + 1, to: after.from - 1) if after.from > before.to + 1
    end
  end
end
