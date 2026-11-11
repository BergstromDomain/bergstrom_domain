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

    trait :personal do
      personal { true }
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

    trait :personal do
      association :employment_type, factory: [ :dossier_employment_type, :personal ]
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
    systems_under_test_na { true }
    operating_systems_na { true }
    methodologies_na     { true }
    test_tools_na        { true }
    other_tools_na       { true }
    protocols_na         { true }
  end

  factory :dossier_achievement, class: "Dossier::Achievement" do
    association :assignment, factory: :dossier_assignment
    sequence(:text) { |n| "Ran daily defect triage for release #{n}" }
  end

  factory :dossier_credential_type, class: "Dossier::CredentialType" do
    sequence(:name) { |n| "Credential Type #{n}" }
    training { false }

    trait :training do
      training { true }
    end
  end

  factory :dossier_contribution, class: "Dossier::Contribution" do
    association :user, factory: [ :user, :content_creator ]
    kind { "talk" }
    sequence(:title) { |n| "Getting Started With Robot Framework #{n}" }
    start_on        { Date.new(2024, 11, 19) }
    start_precision { "day" }
  end

  factory :dossier_credential, class: "Dossier::Credential" do
    association :user, factory: [ :user, :content_creator ]
    # A course by default: one shared Course type, as seeded.
    credential_type { Dossier::CredentialType.find_or_create_by!(name: "Course") { |t| t.training = true } }
    sequence(:title) { |n| "Agile Fundamentals #{n}" }
    start_on        { Date.new(2020, 3, 1) }
    start_precision { "month" }
    end_on          { Date.new(2020, 3, 1) }
    end_precision   { "month" }

    trait :certification do
      credential_type { Dossier::CredentialType.find_or_create_by!(name: "Certification") }
    end
  end

  factory :dossier_cv_variant, class: "Dossier::CvVariant" do
    association :user, factory: [ :user, :content_creator ]
    sequence(:name) { |n| "QE Lead — Company #{n}" }
  end

  # name: the linked Person's full name (the last word their last name),
  # an existing Person of that name, else a new Restricted one of the
  # Assignment's owner.
  factory :dossier_colleague, class: "Dossier::Colleague" do
    transient do
      sequence(:name) { |n| "Colleague #{n}" }
    end
    association :assignment, factory: :dossier_assignment
    person { dossier_contact_person(name, assignment.user || assignment.engagement.user) }
  end

  # A consultant you worked with during the Engagement, on no shared Assignment.
  factory :dossier_engagement_colleague, class: "Dossier::EngagementColleague" do
    transient do
      sequence(:name) { |n| "Engagement Colleague #{n}" }
    end
    association :engagement, factory: :dossier_engagement
    person { dossier_contact_person(name, engagement.user) }
  end

  factory :dossier_assignment_partner, class: "Dossier::AssignmentPartner" do
    association :assignment, factory: :dossier_assignment
    association :organisation, factory: :dossier_organisation
    kind { "vendor" }

    trait :customer do
      kind { "customer" }
    end
  end

  factory :dossier_staff_member, class: "Dossier::StaffMember" do
    transient do
      sequence(:name) { |n| "Staff Member #{n}" }
    end
    association :assignment_partner, factory: :dossier_assignment_partner
    person do
      assignment = assignment_partner.assignment
      dossier_contact_person(name, assignment.user || assignment.engagement.user)
    end
  end
end
