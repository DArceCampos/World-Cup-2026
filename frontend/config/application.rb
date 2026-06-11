require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)

module Frontend
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = false
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
