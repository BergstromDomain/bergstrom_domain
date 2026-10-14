# spec/support/guide_images.rb

# User Guide screenshots: capture_guide_image("recipe-ingredients",
# as: "cookbook/recipe_ingredients") saves that element to
# docs/user-guide/cookbook/images/recipe_ingredients.png, where the guide's
# Markdown can show it. Specs that take them are tagged guide_image: true and
# only run with GUIDE_SCREENSHOTS=1 — they rewrite committed images, so the
# default suite and CI skip them. Element captures only: a full page would
# include the footer's build info, which changes on every commit.
module GuideImages
  # Freezes the page so a re-run gives the same pixels: no transitions or
  # animations caught mid-way, and no blinking text cursor.
  STILL_CSS = <<~CSS.freeze
    *, *::before, *::after {
      transition: none !important;
      animation: none !important;
      caret-color: transparent !important;
    }
  CSS

  class << self
    attr_writer :root

    def root
      @root || Rails.root.join("docs/user-guide")
    end
  end

  def capture_guide_image(testid, as:)
    app, name = as.to_s.split("/", 2)
    raise ArgumentError, "Name the guide image as \"<app folder>/<name>\", got #{as.inspect}" if name.blank?
    raise ArgumentError, "No User Guide folder for #{app.inspect} in #{GuideImages.root}" unless GuideImages.root.join(app).directory?

    hold_still
    path = GuideImages.root.join(app, "images", "#{name.delete_suffix('.png')}.png")
    Dir.mktmpdir do |directory|
      fresh = capture_element(testid, Pathname.new(directory).join(path.basename))
      next if GuideImages.looks_the_same?(fresh, path)

      path.dirname.mkpath
      FileUtils.mv(fresh, path)
    end
    path
  end

  # Same size, and no pixel more than a couple of shades apart — Chrome's
  # anti-aliasing can differ that much between runs of an unchanged screen.
  def self.looks_the_same?(fresh, existing)
    return false unless existing.exist?

    require "vips"
    a = Vips::Image.new_from_file(fresh.to_s)
    b = Vips::Image.new_from_file(existing.to_s)
    a.width == b.width && a.height == b.height && a.bands == b.bands && (a - b).abs.max <= 2
  end

  private

  def hold_still
    page.execute_script(<<~JS, STILL_CSS)
      if (!document.getElementById("guide-image-still")) {
        const style = document.createElement("style")
        style.id = "guide-image-still"
        style.textContent = arguments[0]
        document.head.append(style)
      }
      document.activeElement?.blur()
    JS
  end
end

RSpec.configure do |config|
  config.include GuideImages, type: :feature
  config.filter_run_excluding guide_image: true unless ENV["GUIDE_SCREENSHOTS"].present?
end
