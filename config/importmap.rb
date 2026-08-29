# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Quill (Chronicle's Formatted-tab rich-text editor) — vendored as jsDelivr's
# bundled "+esm" build (single self-contained file per package) rather than via
# `bin/importmap pin`, since Quill's npm package is a multi-file ESM graph with
# relative imports that the standard jspm-based downloader doesn't fully vendor.
pin "quill" # @2.0.3
pin "eventemitter3" # @5.0.1
pin "lodash-es" # @4.17.21
pin "parchment" # @3.0.0
pin "quill-delta" # @5.1.0
pin "fast-diff" # @1.3.0
pin "lodash.clonedeep" # @4.5.0
pin "lodash.isequal" # @4.5.0
