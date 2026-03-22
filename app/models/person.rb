# app/models/person.rb
class Person < ApplicationRecord
  before_validation :normalise_names

  validates :first_name, presence: true
  validate  :full_name_must_be_unique

  def full_name
    [ first_name, middle_name, last_name ].reject(&:blank?).join(" ")
  end

  private

  def normalise_names
    self.middle_name = middle_name.presence
    self.last_name   = last_name.presence
  end

  def full_name_must_be_unique
    return if first_name.blank?

    scope = Person.where(
      first_name:  first_name.strip,
      middle_name: middle_name,
      last_name:   last_name
    )

    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      errors.add(:base, "Full name has already been taken")
    end
  end
end
