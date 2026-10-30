# spec/factories/dossier.rb
FactoryBot.define do
  factory :dossier_industry, class: "Dossier::Industry" do
    sequence(:name) { |n| "Industry #{n}" }
  end

  factory :dossier_role, class: "Dossier::Role" do
    sequence(:name) { |n| "Role #{n}" }
  end

  factory :dossier_skill_category, class: "Dossier::SkillCategory" do
    sequence(:name) { |n| "Skill Category #{n}" }
  end

  factory :dossier_employment_type, class: "Dossier::EmploymentType" do
    sequence(:name) { |n| "Employment Type #{n}" }
    permanent { false }

    trait :permanent do
      permanent { true }
    end
  end

  factory :dossier_location, class: "Dossier::Location" do
    sequence(:city) { |n| "City #{n}" }
    country { "Australia" }
  end

  factory :dossier_organisation, class: "Dossier::Organisation" do
    sequence(:name) { |n| "Organisation #{n}" }
  end

  factory :dossier_skill, class: "Dossier::Skill" do
    sequence(:name) { |n| "Skill #{n}" }
    association :skill_category, factory: :dossier_skill_category
  end

  factory :dossier_profile, class: "Dossier::Profile" do
    association :user, factory: [ :user, :content_creator ]
    display_name { "Alex Example" }
  end

  factory :dossier_engagement, class: "Dossier::Engagement" do
    association :user, factory: [ :user, :content_creator ]
    association :employer, factory: :dossier_organisation
    association :employment_type, factory: :dossier_employment_type
    position_title  { "Test Consultant" }
    start_on        { Date.new(2019, 3, 1) }
    start_precision { "month" }
    end_on          { Date.new(2022, 6, 1) }
    end_precision   { "month" }

    trait :permanent do
      association :employment_type, factory: [ :dossier_employment_type, :permanent ]
    end

    trait :current do
      end_on { nil }
    end
  end

  factory :dossier_assignment, class: "Dossier::Assignment" do
    association :engagement, factory: :dossier_engagement
    association :client, factory: :dossier_organisation
    association :role, factory: :dossier_role
    start_on        { engagement.start_on }
    start_precision { "month" }
    end_on          { engagement.end_on }
    end_precision   { "month" }
    system_under_test   { "N/A" }
    operating_systems_na { true }
    methodologies_na     { true }
    test_tools_na        { true }
    other_tools_na       { true }
    protocols_na         { true }
  end
end
