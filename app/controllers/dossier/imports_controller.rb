# app/controllers/dossier/imports_controller.rb

# Imports a Bridge CV master list: upload → preview → confirm. The file is
# never stored — the preview page carries its text in a hidden field, and
# the confirm step runs the import on that text (re-checking everything, so
# a page left open can't import what already exists).
class Dossier::ImportsController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  MAX_FILE_SIZE = 1.megabyte
  EXTENSIONS = %w[.yaml .yml].freeze

  def new
  end

  def preview
    @text = uploaded_text or return
    @result = Dossier::Import.new(current_user, @text).preview
  end

  def create
    @text = params[:yaml].to_s
    @result = Dossier::Import.new(current_user, @text).import!

    if !@result.ok?
      render :preview, status: :unprocessable_entity
    elsif @result.created.empty?
      redirect_to dossier_engagements_path, flash: { info: "Nothing new to import — everything in the file already exists" }
    else
      counts = @result.created.map { |kind, labels| helpers.pluralize(labels.size, kind) }
      redirect_to dossier_engagements_path, flash: { success: "Master CV imported: #{counts.to_sentence}" }
    end
  end

  private

  def uploaded_text
    file = params[:file]
    if file.blank?
      redirect_to new_dossier_import_path, alert: "Please choose a YAML file to import."
    elsif !EXTENSIONS.include?(File.extname(file.original_filename.to_s).downcase)
      redirect_to new_dossier_import_path, alert: "The file must be a YAML file (.yaml or .yml)."
    elsif file.size > MAX_FILE_SIZE
      redirect_to new_dossier_import_path, alert: "The file is too large (over 1 MB)."
    else
      text = file.read.force_encoding("UTF-8")
      return text if text.valid_encoding?

      redirect_to new_dossier_import_path, alert: "The file must be UTF-8 text."
    end
    nil
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
