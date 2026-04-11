Rails.application.config.tribe = ActiveSupport::OrderedOptions.new
Rails.application.config.tribe.enabled = ENV.fetch("TRIBE_ENABLED", "true") == "true"
Rails.application.config.tribe.python_path = ENV.fetch(
  "TRIBE_PYTHON_PATH",
  "/Users/afmp/Projects/tribev2/.venv/bin/python"
)
Rails.application.config.tribe.script_path = Rails.root.join("script", "tribe_predict.py").to_s
Rails.application.config.tribe.cache_folder = ENV.fetch(
  "TRIBE_CACHE_FOLDER",
  "/Users/afmp/Projects/tribev2/cache"
)
Rails.application.config.tribe.timeout = ENV.fetch("TRIBE_TIMEOUT", "120").to_i
