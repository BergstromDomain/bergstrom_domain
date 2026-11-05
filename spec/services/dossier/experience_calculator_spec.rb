# spec/services/dossier/experience_calculator_spec.rb
require "rails_helper"

RSpec.describe Dossier::ExperienceCalculator do
  let(:user)       { create(:user, :content_creator) }
  let(:today)      { Date.new(2026, 11, 3) }
  let(:engagement) { create(:dossier_engagement, user: user, start_month: "2015-01", end_month: "2022-12") }

  def assignment(from, to, engagement: self.engagement, **stack)
    create(:dossier_assignment, engagement: engagement, start_month: from, end_month: to, **stack)
  end

  def tools(text) = { test_tools_na: false, test_tools_text: text }

  def calculator = described_class.new(user, today: today)
  def experience(name) = calculator.for_skill(Dossier::Skill.find_by!(name: name))

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Counts a Skill's years as the union of its Assignments' dates, not the sum" do
      assignment("2015-01", "2016-12", **tools("Jira"))
      assignment("2016-07", "2018-06", **tools("Jira")) # overlaps the first by six months

      jira = experience("Jira")
      expect(jira.months).to eq(42)
      expect(jira.duration).to eq("3+ years")
      expect(jira.assignments.size).to eq(2)
      expect(jira.last_used).to eq("Jun 2018")
    end

    it "Lists every Skill used, most years first" do
      assignment("2015-01", "2016-12", **tools("Jira, Excel"))
      assignment("2017-01", "2017-03", **tools("Jira"))

      expect(calculator.skills.map { |e| e.skill.name }).to eq(%w[Jira Excel])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves out other users' Assignments" do
      other = create(:dossier_engagement, start_month: "2015-01", end_month: "2022-12")
      assignment("2015-01", "2022-12", engagement: other, **tools("Jira"))

      expect(calculator.skills).to be_empty
    end

    it "Leaves out deleted Engagements and deleted Achievements" do
      assignment("2015-01", "2016-12", **tools("Jira"))
      engagement.soft_delete!
      kept = create(:dossier_engagement, user: user, start_month: "2023-01", end_month: "2023-12")
      create(:dossier_achievement, assignment: assignment("2023-01", "2023-12", engagement: kept), skills_text: "Selenium")
        .soft_delete!

      expect(calculator.skills).to be_empty
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Counts a Skill tagged only on an Achievement over that Achievement's Assignment" do
      create(:dossier_achievement, assignment: assignment("2016-07", "2018-06"), skills_text: "Selenium")

      selenium = experience("Selenium")
      expect(selenium.duration).to eq("2+ years")
      expect(selenium.slots.keys).to eq([ :achievement ])
      expect(selenium.achievements.map(&:text)).to eq([ Dossier::Achievement.sole.text ])
    end

    it "Groups the Assignments by Tech Stack list, one Assignment in two lists" do
      used_twice = assignment("2015-01", "2016-12", **tools("Excel"), other_tools_na: false, other_tools_text: "Excel")

      excel = experience("Excel")
      expect(excel.slots).to eq(test_tool: [ used_twice ], other_tool: [ used_twice ])
      expect(excel.assignments).to eq([ used_twice ])
      expect(excel.months).to eq(24)
    end

    it "Counts personal projects' time apart from professional years" do
      hobby = create(:dossier_engagement, :personal, user: user, start_month: "2016-01", end_month: "2019-12")
      assignment("2015-01", "2016-12", **tools("Jira, Rails"))
      assignment("2016-01", "2019-12", engagement: hobby, **tools("Rails, Sass"))

      rails = experience("Rails")
      expect([ rails.duration, rails.personal_duration ]).to eq([ "2+ years", "4+ years" ])
      expect(rails.last_used).to eq("Dec 2019")
      sass = experience("Sass")
      expect([ sass.months, sass.personal_duration ]).to eq([ nil, "4+ years" ])
      expect(experience("Jira").personal_months).to be_nil
      # Professional years sort first (Sass's 4 personal years come last);
      # personal years break the Jira/Rails tie.
      expect(calculator.skills.map { |e| e.skill.name }).to eq(%w[Rails Jira Sass])
    end

    it "Lists Training with a Skill but never adds it to years" do
      assignment("2015-01", "2016-12", **tools("Jira"))
      course = create(:dossier_credential, user: user, skills_text: "Jira, Excel VBA")

      jira = experience("Jira")
      expect(jira.training).to eq([ course ])
      expect(jira.duration).to eq("2+ years")
      vba = experience("Excel VBA")
      expect([ vba.duration, vba.personal_duration, vba.last_used, vba.assignments ]).to eq([ nil, nil, "—", [] ])
      expect(vba).not_to be_current
    end

    it "Shows a current Assignment as last used Present, counted up to today" do
      current = create(:dossier_engagement, :current, user: user, start_month: "2026-05")
      assignment("2026-05", "", engagement: current, **tools("Jira"))

      jira = experience("Jira")
      expect(jira.last_used).to eq("Present")
      expect(jira.duration).to eq("6 months")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Returns nil for a Skill the user hasn't used" do
      expect(calculator.for_skill(create(:dossier_skill))).to be_nil
    end

    it "Says Under a month for a Skill used for days" do
      assignment("2015-01", "2015-01", **tools("Jira"), end_day: "10", start_day: "1")

      expect(experience("Jira").duration).to eq("Under a month")
    end
  end
end
