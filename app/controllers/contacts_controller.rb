# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  include Navigable

  before_action :set_contact,           only: %i[confirm destroy]
  before_action :authorize_recipient!,  only: :confirm
  before_action :authorize_participant!, only: :destroy

  def index
    @incoming_pending = Contact.where(contact: current_user, status: :pending)
                                .joins(:user)
                                .order("users.last_name, users.first_name")
                                .preload(:user)

    @outgoing_pending = Contact.where(user: current_user, status: :pending)
                                .joins(:contact)
                                .order("users.last_name, users.first_name")
                                .preload(:contact)

    # The "other" user alternates between the user/contact columns depending
    # on who sent the original request, so a plain ORDER BY can't express
    # it — a CASE expression over both aliased sides of the self-join can.
    @confirmed = Contact.confirmed
                         .where("contacts.user_id = :id OR contacts.contact_id = :id", id: current_user.id)
                         .joins("INNER JOIN users AS requesters ON requesters.id = contacts.user_id")
                         .joins("INNER JOIN users AS recipients ON recipients.id = contacts.contact_id")
                         .order(Arel.sql(Contact.sanitize_sql_array([
                           "CASE WHEN contacts.user_id = ? THEN recipients.last_name  ELSE requesters.last_name  END,
                            CASE WHEN contacts.user_id = ? THEN recipients.first_name ELSE requesters.first_name END",
                           current_user.id, current_user.id
                         ])))
                         .preload(:user, :contact)
  end

  def create
    target = User.find_by(id: params[:user_id])

    unless target
      redirect_to contacts_path, alert: "User not found."
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

  def search
    query = params[:q].to_s.strip
    related_ids = Contact.where("user_id = :id OR contact_id = :id", id: current_user.id)
                          .pluck(:user_id, :contact_id).flatten.to_set
    related_ids << current_user.id

    @results = if query.blank?
      User.none
    else
      User.where.not(id: related_ids)
          .where("first_name ILIKE :q OR last_name ILIKE :q", q: "%#{User.sanitize_sql_like(query)}%")
          .order(:last_name, :first_name)
          .limit(10)
    end

    render partial: "contacts/search_results", locals: { results: @results }, layout: false
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
