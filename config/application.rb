# frozen_string_literal: true

module OurApp
  class Application < Rails::Application
    config.load_defaults 5.2

    # rswag requires this to generate examples on the fly
    if defined? RSpec
      RSpec.configure do |config|
        config.swagger_dry_run = false
      end
    end
  end
end
