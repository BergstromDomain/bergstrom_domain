# app/controllers/dossier/reference_data_controller.rb

# Shared CRUD for Dossier reference data. Anyone can list/view; admins (or a
# Dossier AppPermission override) can edit/delete. Creating is admin-only too,
# except where a subclass sets content_creators_can_create (Organisations and
# Skills, which Content Creators need for their own Engagements and Tech Stacks).
#
# Views live in app/views/dossier/reference_data/; a subclass only adds a
# _fields partial (the form) and #details (the show page's extra rows).
class Dossier::ReferenceDataController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_record, only: %i[show edit update destroy]
  before_action :set_policy, only: %i[show edit update destroy]
  before_action :require_create_access, only: %i[new create]

  class_attribute :content_creators_can_create, default: false

  helper_method :model_class, :singular_name, :plural_name, :subtitle, :details

  def index
    @records = model_class.alphabetical
  end

  def show
  end

  def new
    @record = model_class.new
  end

  def create
    @record = model_class.new(record_params)
    if @record.save
      toast_created(@record)
      redirect_to @record
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to index_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to index_path, alert: "Not authorised." and return
    end
    previous_label = @record.to_toast_label
    if @record.update(record_params)
      toast_updated(@record, previous_label: previous_label)
      redirect_to @record
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to index_path, alert: "Not authorised." and return
    end
    @record.destroy
    if @record.errors.any?
      toast_error(@record)
      redirect_to @record
    else
      toast_deleted(@record)
      redirect_to index_path
    end
  end

  private

  # ── Subclass hooks ────────────────────────────────────────────────────────
  def model_class        = raise(NotImplementedError)
  def permitted_attributes = %i[name description]
  def subtitle           = nil

  # [label, value, testid] rows for the show page, after the name.
  def details(_record) = []

  # ── Shared ────────────────────────────────────────────────────────────────
  def singular_name = model_class.model_name.human.titleize
  def plural_name   = singular_name.pluralize
  def index_path    = polymorphic_path(model_class)

  def record_params
    params.require(model_class.model_name.param_key).permit(*permitted_attributes)
  end

  def require_create_access
    allowed = content_creators_can_create ? Policy.new(current_user, model_class.new).can_create? : current_user&.can_administer?
    redirect_to index_path, alert: "Not authorised." unless allowed
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_record
    @record = model_class.friendly.find(params[:id])
  end

  def set_policy
    @policy = Policy.new(current_user, @record)
  end
end
