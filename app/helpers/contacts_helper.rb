module ContactsHelper
  def other_party(contact, user)
    contact.user_id == user.id ? contact.contact : contact.user
  end
end
