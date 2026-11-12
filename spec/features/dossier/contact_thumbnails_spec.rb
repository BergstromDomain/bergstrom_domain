# spec/features/dossier/contact_thumbnails_spec.rb
require "rails_helper"

# Every Dossier contacts table (an Assignment's Colleagues, its Vendors' and
# Customers' Staff, an Engagement's Colleagues) starts each row with the
# Person's thumbnail, or a person icon, linking to the Person.
RSpec.describe "Dossier contact thumbnails", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let(:chris)      { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: charlie) }
  let(:assignment) { create(:dossier_assignment, engagement: engagement) }

  def with_image(contact)
    contact.person.image.attach(file_fixture("test_image.jpg"))
    contact
  end

  def thumbnail(row) = row.find("[data-testid='contact-thumbnail']")

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows a Colleague's image on the Assignment page, linking to the Person" do
      colleague = with_image(create(:dossier_colleague, assignment: assignment, name: "Andrew Job"))
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      cell = thumbnail(find("[data-testid='colleague-row']"))
      expect(cell).to have_css("img.table-thumbnail--person[alt='Andrew Job']")
      expect(cell).to have_link(href: person_path(colleague.person))
    end

    it "Shows Vendor and Customer Staff images, and an Engagement Colleague's" do
      vendor = create(:dossier_assignment_partner, assignment: assignment)
      customer = create(:dossier_assignment_partner, :customer, assignment: assignment)
      with_image(create(:dossier_staff_member, assignment_partner: vendor, name: "Priya Patel"))
      with_image(create(:dossier_staff_member, assignment_partner: customer, name: "Sam Lee"))
      with_image(create(:dossier_engagement_colleague, engagement: engagement, name: "Delenn Palmer"))
      sign_in_as(charlie)

      visit dossier_assignment_path(assignment)
      expect(find("[data-testid='vendors']")).to have_css("[data-testid='contact-thumbnail'] img[alt='Priya Patel']")
      expect(find("[data-testid='customers']")).to have_css("[data-testid='contact-thumbnail'] img[alt='Sam Lee']")
      visit dossier_engagement_path(engagement)
      expect(find("[data-testid='engagement-colleague-row']")).to have_css("[data-testid='contact-thumbnail'] img[alt='Delenn Palmer']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows a person icon for a Colleague with no image" do
      colleague = create(:dossier_colleague, assignment: assignment)
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      cell = thumbnail(find("[data-testid='colleague-row']"))
      expect(cell).not_to have_css("img")
      expect(cell).to have_css("a.table-thumbnail-icon--person[href='#{person_path(colleague.person)}'] svg")
    end

    it "Shows Chris no thumbnails of Charlie's Colleagues on Charlie's Unrestricted Assignment" do
      [ engagement, assignment ].each { |record| record.update!(classification: "unrestricted") }
      with_image(create(:dossier_colleague, assignment: assignment))
      sign_in_as(chris)
      visit dossier_assignment_path(assignment)

      expect(page).not_to have_selector("[data-testid='contact-thumbnail']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Puts the thumbnail in the first column, before the Name" do
      create(:dossier_colleague, assignment: assignment)
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      headers = find("[data-testid='colleagues-table']").all("th").map(&:text)
      expect(headers.first(2)).to eq([ "", "Name" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Mixes images and icons in one table" do
      with_image(create(:dossier_colleague, assignment: assignment))
      create(:dossier_colleague, assignment: assignment)
      sign_in_as(charlie)
      visit dossier_assignment_path(assignment)

      cells = all("[data-testid='contact-thumbnail']")
      expect(cells.count { |cell| cell.has_css?("img", wait: 0) }).to eq(1)
      expect(cells.size).to eq(2)
    end
  end
end
