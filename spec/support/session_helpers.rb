# frozen_string_literal: true

module Features
  module Swagger
    module Helpers
      def authorize_user
        let('Authorization') do
          "Bearer #{Doorkeeper::AccessToken.create!(
            resource_owner_id: user.id,
            application_id: Doorkeeper::Application.first.id,
            scopes: Doorkeeper.configuration.default_scopes.first
          ).token}"
        end
      end

      def generate_example
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
      end
    end
  end
end
