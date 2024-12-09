# spec/requests/api/v1/assets_spec.rb
require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'API V1 Assets', type: :request do
  let(:user) { create(:user) }
  let(:organization) do
    create(:organization, owner: user).tap do |org|
      org.members << user unless org.members.include?(user)
    end
  end
  let(:Authorization) { auth_token(user) }
  let(:organization_id) { organization.id }



  path '/api/v1/organizations/{organization_id}/assets' do
    parameter name: :organization_id, in: :path, type: :string, required: true

    get 'Lists assets' do
      tags 'Assets'
      description 'Returns a paginated list of organization assets'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'assets found' do
        let(:organization_id) { organization.id }

        before do
          create_list(:asset, 3, organization: organization, created_by: user)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assets'].length).to eq(3)
          expect(data['meta']).to include('total_count', 'total_pages', 'current_page')
        end
      end

      response '404', 'organization not found' do
        let(:organization_id) { 'invalid' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:organization_id) { organization.id }
        run_test!
      end
    end

    post 'Creates an asset' do
      tags 'Assets'
      description 'Creates a new asset in the organization'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :asset, in: :body, schema: {
        type: :object,
        properties: {
          asset: {
            type: :object,
            properties: {
              name: { type: :string },
              content_type: { type: :string },
              byte_size: { type: :integer },
              storage_provider: { type: :string, enum: [ 's3', 'distributed' ] },
              storage_key: { type: :string },
              storage_path: { type: :string },
              metadata: { type: :object }
            },
            required: %w[name content_type byte_size storage_provider storage_key storage_path]
          }
        }
      }

      response '201', 'asset created' do
        let(:organization_id) { organization.id }
        let(:asset) do
          {
            asset: {
              name: 'test.pdf',
              content_type: 'application/pdf',
              byte_size: 1024,
              storage_provider: 's3',
              storage_key: 'test/test.pdf',
              storage_path: 'https://s3.amazonaws.com/bucket/test/test.pdf',
              metadata: { original_name: 'test.pdf' }
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('test.pdf')
          expect(data['storage_provider']).to eq('s3')
        end
      end

      response '422', 'invalid request' do
        let(:organization_id) { organization.id }
        let(:asset) do
          {
            asset: {
              name: '',
              content_type: '',
              byte_size: -1
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to be_present
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:organization_id) { organization.id }
        let(:asset) { {} }
        run_test!
      end
    end
  end

  path '/api/v1/organizations/{organization_id}/assets/{id}' do
    parameter name: 'Authorization', in: :header, type: :string, required: true
    parameter name: :organization_id, in: :path, type: :string, description: 'Organization ID'
    parameter name: :id, in: :path, type: :string, description: 'Asset ID'

    get 'Retrieves an asset' do
      tags 'Assets'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '200', 'asset found' do
        let(:asset) { create(:asset, organization: organization, created_by: user) }
        let(:organization_id) { organization.id }
        let(:id) { asset.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(asset.id)
        end
      end

      response '404', 'asset not found' do
        let(:organization_id) { organization.id }
        let(:id) { 'invalid' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:organization_id) { organization.id }
        let(:id) { 'invalid' }
        run_test!
      end
    end

    delete 'Deletes an asset' do
      tags 'Assets'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '204', 'asset deleted' do
        let(:asset) { create(:asset, organization: organization, created_by: user) }
        let(:organization_id) { organization.id }
        let(:id) { asset.id }

        run_test! do
          expect(Asset.exists?(id)).to be false
        end
      end

      response '404', 'asset not found' do
        let(:organization_id) { organization.id }
        let(:id) { 'invalid' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        let(:organization_id) { organization.id }
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
