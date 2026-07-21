# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  include Navigable

  before_action :set_contact,           only: %i[confirm destroy]
  before_action :authorize_recipient!,  only: :confirm
  before_action :authorize_participant!, only: :destroy

  def index
    @incoming_pending = Contact.where(contact: current_user, status: :pending)
    @outgoing_pending = Contact.where(user: current_user, status: :pending)
    @confirmed = Contact.confirmed
                        .where(user: current_user)
                        .or(Contact.confirmed.where(contact: current_user))
  end

  def create
    target = User.find_by(email_address: params[:email_address])

    unless target
      redirect_to contacts_path, alert: "No user found with that email address."
      return
    end

    # An implicit acceptance: if the target already has a pending request out
    # to the current user, sending one back just connects the two of you —
    # rather than leaving two separate pending rows.
    reverse = Contact.find_by(user: target, contact: current_user, status: :pending)
    if reverse
      reverse.confirmed!
      redirect_to contacts_path, notice: "You are now connected with #{target.first_name}."
      return
    end

    contact = Contact.new(user: current_user, contact: target, status: :pending)
    if contact.save
      redirect_to contacts_path, notice: "Request sent to #{target.first_name}."
    else
      redirect_to contacts_path, alert: contact.errors.full_messages.to_sentence
    end
  end

  def confirm
    @contact.confirmed!
    redirect_to contacts_path, notice: "You are now connected with #{@contact.user.first_name}."
  end

  def destroy
    was_confirmed = @contact.confirmed?
    other         = other_party
    @contact.destroy!

    if was_confirmed
      redirect_to contacts_path, notice: "#{other.first_name} #{other.last_name} has been removed from your contacts."
    else
      redirect_to contacts_path, notice: "Contact request with #{other.first_name} #{other.last_name} was removed."
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def other_party
    @contact.user_id == current_user.id ? @contact.contact : @contact.user
  end

  def authorize_recipient!
    redirect_to contacts_path, alert: "Not authorised." unless @contact.contact_id == current_user.id
  end

  def authorize_participant!
    return if @contact.user_id == current_user.id || @contact.contact_id == current_user.id
    redirect_to contacts_path, alert: "Not authorised."
  end
end
