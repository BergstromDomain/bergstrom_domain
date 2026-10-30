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
end
