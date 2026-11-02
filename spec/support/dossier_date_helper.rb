# spec/support/dossier_date_helper.rb

# Fills a Dossier date edge's Year and Month fields from "2019-03" ("" clears
# both). Usage: fill_in_dossier_month "Start", with: "2019-03"
module DossierDateHelper
  def fill_in_dossier_month(label, with:)
    year, month = with.to_s.split("-")
    fill_in "#{label} Year", with: year.to_s
    select(month ? Date::MONTHNAMES[month.to_i] : "Choose a month", from: "#{label} Month")
  end
end
