require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.action_controller.perform_caching = false
  config.action_controller.enable_fragment_cache_logging = true

  config.assets.debug = true
  config.assets.quiet = true

  config.log_level = :debug
  config.log_tags = [:request_id]
end
