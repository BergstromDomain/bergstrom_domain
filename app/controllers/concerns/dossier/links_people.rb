# app/controllers/concerns/dossier/links_people.rb

# For the Colleague and Staff member forms (Dossier::ContactDetails): the New
# page finds People you can see by name (?q=) and links the one picked
# (?person_id=); without one, the form's name adds a new Restricted Person
# owned by the Assignment's owner. The form edits the linked Person's name,
# Work Email and LinkedIn directly when you may update that Person, and only
# shows them otherwise.
module Dossier::LinksPeople
  extend ActiveSupport::Concern

  SEARCH_LIMIT = 10
  FULL_NAME_SQL = "CONCAT_WS(' ', people.first_name, NULLIF(people.middle_name, ''), people.last_name)"

  included do
    helper_method :person_editable?
  end

  private

  def visible_people
    current_user.can_administer? ? Person.visible_to_admins : Person.visible_to_users(current_user)
  end

  # @query and @people_found for the New page's search.
  def find_people
    @query = params[:q].to_s.squish
    @people_found = if @query.length >= 2
      visible_people.where("#{FULL_NAME_SQL} ILIKE ?", "%#{Person.sanitize_sql_like(@query)}%")
                    .order(:first_name, :last_name).limit(SEARCH_LIMIT)
    else
      Person.none
    end
  end

  # The picked Person (one you can see), or a new one for the form to fill in.
  def pick_person(contact, person_id)
    contact.person = visible_people.find_by(id: person_id) if person_id.present?
    contact.build_person if contact.person.nil?
  end

  # The contact's own fields, and the Person's when they may be changed: a new
  # Person is Restricted and the Assignment owner's.
  def assign_contact(contact, attributes)
    attributes = attributes.to_h
    person_attributes = attributes.delete("person_attributes") || {}
    contact.assign_attributes(attributes)
    person = contact.person
    return unless person && person_editable?(person)

    person.assign_attributes(person_attributes)
    if person.new_record?
      person.assign_attributes(user: @assignment.user, classification: "restricted")
    else
      person.updater = current_user
    end
  end

  def person_editable?(person) = person.new_record? || Policy.new(current_user, person).can_update?

  def contact_params(key)
    params.require(key).permit(*Dossier::ContactDetails::FIELDS, person_attributes: Dossier::ContactDetails::PERSON_FIELDS)
  end
end
