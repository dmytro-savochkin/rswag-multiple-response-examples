# frozen_string_literal: true

require 'rails_helper'
require 'rspec/core/formatters/base_text_formatter'

RSpec.configure do |config|
  Rswag::Specs::RequestFactory.prepend Extensions::Rswag::Specs::ExtendedRequestFactory
  config.extend Features::Swagger::Helpers, type: :request

  config.swagger_root = Rails.root.join('swagger').to_s
  config.swagger_format = :yaml
  config.swagger_docs = {
    'swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API',
        version: 'v1'
      },
      paths: {},
      components: {
        securitySchemes: {
          bearer: {
            type: :http,
            scheme: :bearer
          }
        }
      }
    }
  }

  module Rswag
    module Specs
      class SwaggerFormatter < ::RSpec::Core::Formatters::BaseTextFormatter
        ::RSpec::Core::Formatters.register(self, :example_group_finished, :stop)

        prepend ::Extensions::Rswag::Specs::ExtendedSwaggerFormatter
      end
    end
  end
end
