# app/helpers/dossier_helper.rb
module DossierHelper
  # The page for a Timeline bench or gap period (a Dossier::Timeline::Period).
  def period_path_for(period)
    dossier_period_path(from: period.from.iso8601, to: period.to.iso8601)
  end

  # What the Profile's three summaries are for, for an info tip.
  def profile_summaries_info
    safe_join([
      tag.strong("Summary"), " is the terse form, with no \"I\" and no name: \"Test manager with 25+ years…\". ",
      "CVs use it wherever a voice has no version of its own. ",
      tag.strong("First-Person Summary"), " speaks as you, \"I lead…\", for cover letters and LinkedIn. ",
      tag.strong("Third-Person Summary"), " uses your Third-Person Name, \"Alex leads…\", for bios and introductions."
    ])
  end
end
