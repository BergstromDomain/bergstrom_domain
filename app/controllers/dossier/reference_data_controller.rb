# app/controllers/dossier/reference_data_controller.rb

# Shared CRUD for Dossier reference data. Anyone can list/view; admins (or a
# Dossier AppPermission override) can edit/delete. Creating is admin-only too,
# except where a subclass sets content_creators_can_create (Organisations and
# Skills, which Content Creators need for their own Engagements and Tech Stacks).
#
# Views live in app/views/dossier/reference_data/; a subclass only adds a
# _fields partial (the form), #details (the show page's extra rows) and,
# where Assignments use the record, #assignments_for (the signed-in user's
# own Assignments listed on the show page) and #experience_slices (the
# signed-in user's years with the record, from Dossier::ExperienceCalculator).
class Dossier::ReferenceDataController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_record, only: %i[show edit update destroy]
  before_action :set_policy, only: %i[show edit update destroy]
  before_action :require_create_access, only: %i[new create]

  class_attribute :content_creators_can_create, default: false

  helper_method :model_class, :singular_name, :plural_name, :subtitle, :details, :index_groups, :show_panels, :show_actions

  def index
    @records = model_class.alphabetical
  end

  def show
    @assignments = related_assignments
    @slice_experience = related_experience
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

  # [heading, records] pairs for the index; a nil heading shows no subheader.
  def index_groups = [ [ nil, @records ] ]

  # Partials with extra show-page panels (before the actions) and extra
  # action buttons; nil for none.
  def show_panels  = nil
  def show_actions = nil

  # Narrows the given Assignments to those using record; nil when
  # Assignments don't use this kind of record.
  def assignments_for(_record, _assignments) = nil

  # [label, slice] pairs for the Your Experience panel, e.g.
  # [ [ "As Employer", :employer ] ]; empty when it doesn't apply.
  def experience_slices = []

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

  # Only the signed-in user's own, so a public page never lists anyone's
  # (restricted) Assignments; nil when there are none.
  def related_assignments
    return unless current_user

    mine = Dossier::Assignment.kept.where(engagement_id: current_user.dossier_engagements.kept.select(:id))
    assignments_for(@record, mine)&.includes(:client)&.newest_first&.to_a.presence
  end

  # [label, slice, row] for each slice the signed-in user has experience in;
  # nil for a visitor, or when there's none.
  def related_experience
    return if experience_slices.empty? || !Policy.new(current_user, :dossier).can_create?

    calculator = Dossier::ExperienceCalculator.new(current_user)
    experience_slices.filter_map do |label, slice|
      row = calculator.experience_for(slice, @record)
      [ label, slice, row ] if row
    end.presence
  end

  def set_policy
    @policy = Policy.new(current_user, @record)
  end
end
