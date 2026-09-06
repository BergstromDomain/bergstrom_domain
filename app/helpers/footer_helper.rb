# app/helpers/footer_helper.rb
module FooterHelper
  UNKNOWN = "unknown".freeze

  ENVIRONMENT_LABELS = {
    "development" => "DEV",
    "test" => "TEST"
  }.freeze

  def footer_version
    version = build_info_service.version
    version ? "v#{version}" : UNKNOWN
  end

  def footer_deploy_date
    build_date = build_info_service.build_date
    return UNKNOWN if build_date.blank?

    Date.parse(build_date).strftime("%-d-%b-%Y")
  rescue ArgumentError, TypeError
    UNKNOWN
  end

  def footer_git_sha
    build_info_service.git_sha || UNKNOWN
  end

  def footer_environment_label
    ENVIRONMENT_LABELS[Rails.env]
  end

  def show_footer_environment_row?
    !Rails.env.production?
  end

  def footer_class
    @show_left_nav ? "site-footer site-footer--indented" : "site-footer"
  end

  private

  def build_info_service
    @build_info_service ||= BuildInfoService.new
  end
end
