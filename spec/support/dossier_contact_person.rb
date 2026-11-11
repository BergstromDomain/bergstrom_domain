# spec/support/dossier_contact_person.rb

# For the Colleague and Staff member factories: the Person a contact named
# "Anna Andersson" links to — whoever already has that full name, else a new
# Restricted Person (first name "Anna", last name "Andersson") owned by user.
module DossierContactPerson
  def dossier_contact_person(name, user)
    *first, last = name.squish.split
    first, last = [ last ], nil if first.empty?
    Person.all.find { |person| person.full_name.casecmp?(name.squish) } ||
      FactoryBot.create(:person, first_name: first.join(" "), last_name: last, user: user, classification: "restricted")
  end
end

FactoryBot::SyntaxRunner.include(DossierContactPerson)
