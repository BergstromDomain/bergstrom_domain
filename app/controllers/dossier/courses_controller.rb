# app/controllers/dossier/courses_controller.rb

# The signed-in user's Courses (Credentials of a training type), every
# status: Browse Courses drills down by provider (Issued By); Filter Courses
# narrows by provider, status, Skill, year completed and title, in a sortable
# table. Both are the owner's own, like Credentials › Credentials.
class Dossier::CoursesController < ApplicationController
  include Navigable
  include Browsable

  before_action :require_dossier_access

  TABLE_INCLUDES = [ :provider, { engagement: :employer }, { assignment: :client }, { credential_skills: :skill } ].freeze

  def browse
    level = BrowseTree::Level.new(key: :provider_id, association: :provider, records: providers)
    return unless load_browse_tree(scope: courses, levels: [ level ], root_label: "Courses",
                                   path_helper: :dossier_browse_courses_path)

    @courses = @browse_tree.items&.reorder(nil)&.newest_first&.includes(*TABLE_INCLUDES)
  end

  def filter
    @filter = filter_params
    scope = courses.newest_first.includes(*TABLE_INCLUDES)
    scope = scope.where(provider: providers.friendly.find(@filter[:provider_id])) if provider_given?
    scope = scope.where(status: @filter[:status]) if Dossier::Credential::STATUS_LABELS.key?(@filter[:status])
    scope = scope.where(id: Dossier::CredentialSkill.where(skill_id: @filter[:skill_id]).select(:credential_id)) if @filter[:skill_id].present?
    scope = scope.where(end_on: Date.new(@filter[:year].to_i).all_year) if @filter[:year].to_s.match?(/\A\d{4}\z/)
    scope = scope.where("dossier_credentials.title ILIKE ?", "%#{Dossier::Credential.sanitize_sql_like(@filter[:q])}%") if @filter[:q].present?
    @sort = Dossier::CredentialSort.new(params[:sort], params[:direction],
                                        taken_during: ->(credential) { helpers.credential_taken_during_label(credential) })
    @courses = @sort.apply(scope)
    @providers = providers
    @skills = Dossier::Skill.where(id: Dossier::CredentialSkill.where(credential_id: courses.select(:id)).select(:skill_id))
                            .order(Arel.sql("LOWER(dossier_skills.name)")).to_a
    Dossier::Skill.preload_vendors(@skills)
  end

  private

  def courses = current_user.dossier_credentials.kept.training

  # Organisations that issued at least one of the user's Courses, A–Z.
  def providers
    Dossier::Organisation.where(id: courses.select(:provider_id)).order(Arel.sql("LOWER(dossier_organisations.name)"))
  end

  def provider_given? = @filter[:provider_id].present? && providers.friendly.exists?(@filter[:provider_id])

  def filter_params = params.permit(:provider_id, :status, :skill_id, :year, :q).to_h.symbolize_keys

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
