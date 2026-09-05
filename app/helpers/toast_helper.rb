# app/helpers/toast_helper.rb
module ToastHelper
  TOAST_VARIANTS = {
    "notice" => "success",
    "alert" => "error",
    "success" => "success",
    "info" => "info",
    "warning" => "warning",
    "error" => "error"
  }.freeze

  TOAST_ICONS = {
    "success" => "circle-check",
    "info" => "info",
    "warning" => "triangle-alert",
    "error" => "circle-alert"
  }.freeze

  # "What happened" (success/error) stacks above "detail" (warning/info) — see the toast
  # feature's Behaviour Spec. Sorted explicitly rather than relying on flash insertion order,
  # since a controller could plausibly assign flash[:info] before flash[:success] in a redirect's
  # `flash:` hash literal.
  TOAST_ORDER = %w[success error warning info].freeze

  def toast_variant_for(flash_key)
    TOAST_VARIANTS.fetch(flash_key.to_s, "info")
  end

  def toast_icon_for(variant)
    TOAST_ICONS.fetch(variant.to_s, "info")
  end
end
