# frozen_string_literal: true

require 'swagger_helper'

describe 'User Emails', type: :request do
  path '/emails/{id}' do
    delete 'Delete user email' do
      tags 'emails'

      consumes 'application/json'
      produces 'application/json'

      security [bearer: []]

      parameter name: :id, in: :path, type: :string, description: 'Unique id email'

      response '200', 'Deleted' do
        let(:user) { create :user }
        let(:email) { create :email, user: user, preferred: false }
        let(:id) { user_email.id }

        authorize_user
        generate_example
        run_test!
      end

      response '403', 'Cannot delete user last email' do
        let(:user) { create :user }
        let(:id) { user.emails.first.id }

        authorize_user
        generate_example
        run_test!
      end

      response '403', 'Cannot delete user preferred email' do
        let(:user) { create :user }
        let(:email) { create :email, user: user, preferred: true }
        let(:id) { email.id }

        authorize_user
        generate_example
        run_test!
      end
    end
  end
end
