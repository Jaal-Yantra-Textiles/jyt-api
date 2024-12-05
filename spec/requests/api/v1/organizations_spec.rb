require 'swagger_helper'

RSpec.describe "Api::V1::Organizations API", type: :request do
  let(:user) { create(:user) }
  let!(:organizations) { create_list(:organization, 5, owner: user) }
  let(:auth_token) { auth_headers(user)[:Authorization] }

  path '/api/v1/organizations' do
    get 'Lists all organizations' do
      tags 'Organizations'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'organizations found' do
        let(:Authorization) { auth_token }

        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              industry: { type: :string },
              owner_id: { type: :integer }
            }
          }

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(json_response.size).to eq(5)
        end
      end
    end

    post 'Creates an organization' do
      tags 'Organizations'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :organization, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'New Organization' },
          industry: { type: :string, example: 'Textiles' }
        },
        required: ['name', 'industry']
      }

      response '201', 'organization created' do
        let(:Authorization) { auth_token }
        let(:organization) { { name: 'New Organization', industry: 'Textiles' } }

        run_test! do
          expect(response).to have_http_status(:created)
          expect(Organization.count).to eq(6)
        end
      end
    end
  end

  path '/api/v1/organizations/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Retrieves an organization' do
      tags 'Organizations'
      produces 'application/json'
      security [bearer_auth: []]

      response '200', 'organization found' do
        let(:Authorization) { auth_token }
        let(:id) { organizations.first.id }

        schema type: :object,
          properties: {
            id: { type: :integer },
            name: { type: :string },
            industry: { type: :string },
            owner_id: { type: :integer }
          }

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(json_response['id']).to eq(organizations.first.id)
        end
      end
    end

    put 'Updates an organization' do
      tags 'Organizations'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :organization, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Updated Organization' },
          industry: { type: :string }
        }
      }

      response '200', 'organization updated' do
        let(:Authorization) { auth_token }
        let(:id) { organizations.first.id }
        let(:organization) { { name: 'Updated Organization' } }

        run_test! do
          expect(response).to have_http_status(:ok)
          expect(organizations.first.reload.name).to eq('Updated Organization')
        end
      end
    end

    delete 'Deletes an organization' do
      tags 'Organizations'
      security [bearer_auth: []]

      response '204', 'organization deleted' do
        let(:Authorization) { auth_token }
        let(:id) { organizations.first.id }

        run_test! do
          expect(response).to have_http_status(:no_content)
          expect(Organization.count).to eq(4)
        end
      end
    end
  end
end
