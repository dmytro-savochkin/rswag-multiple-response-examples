# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.swagger_root = Rails.root.to_s + '/swagger'
end
