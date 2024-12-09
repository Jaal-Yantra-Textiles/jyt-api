require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Api::V1::DynamicModels', type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, owner: user, members: [ user ]) }
  let(:another_organization) { create(:organization) }
  let(:Authorization) { auth_token(user) }

  # Clean up any test tables after each example
  after(:each) do
    if @model_definition
      table_name = "org_#{organization.id}_#{@model_definition.name.underscore.pluralize}"
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_name} CASCADE")
    end
  end

  describe "Access control" do
    it "returns unauthorized without valid token" do
      post "/api/v1/organizations/#{organization.id}/dynamic_models",
        params: { dynamic_model_definition: { name: "Test" } }.to_json,
        headers: { 'Content-Type': 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not found for inaccessible organization" do
      post "/api/v1/organizations/#{another_organization.id}/dynamic_models",
        params: { dynamic_model_definition: { name: "Test" } }.to_json,
        headers: { 'Authorization' => auth_token(user), 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:not_found)
    end
  end

  path '/api/v1/organizations/{organization_id}/dynamic_models' do
    post 'Creates a dynamic model definition' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      consumes 'application/json'
      parameter name: :organization_id, in: :path, type: :string
      parameter name: :dynamic_model_definition, in: :body, schema: {
        type: :object,
        properties: {
          dynamic_model_definition: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              field_definitions_attributes: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    name: { type: :string },
                    field_type: { type: :string },
                    options: { type: :object }
                  }
                }
              }
            }
          }
        }
      }

      response '201', 'dynamic model created' do
        let(:organization_id) { organization.id }
        let(:dynamic_model_definition) do
          {
            dynamic_model_definition: {
              name: 'Project',
              description: 'A test project model',
              field_definitions_attributes: [
                {
                  name: 'title',
                  field_type: 'string',
                  options: {
                    required: true,
                    default: '',
                    validations: {
                      presence: true,
                      length: { maximum: 100 }
                    }
                  }
                },
                {
                  name: 'status',
                  field_type: 'string',
                  options: {
                    required: true,
                    default: 'pending',
                    validations: {
                      presence: true,
                      inclusion: { in: [ 'pending', 'active', 'completed' ] }
                    }
                  }
                }
              ]
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:created)
          json = json_response

          @model_definition = DynamicModelDefinition.find(json['data']['id'])

          expect(json['data']['attributes']['name']).to eq('Project')
          expect(json['data']['attributes']['fields_attributes'].length).to eq(2)

          table_name = "org_#{organization.id}_projects"
          expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be true

          columns = ActiveRecord::Base.connection.columns(table_name).map(&:name)
          expect(columns).to include('title', 'status', 'organization_id')

          expect(Object.const_defined?("Org#{organization.id}Project")).to be true
        end
      end

      response '422', 'invalid request' do
        let(:organization_id) { organization.id }
        let(:dynamic_model_definition) { { dynamic_model_definition: { name: '' } } }

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors']).to include("Name can't be blank")
        end
      end
    end
  end

  path '/api/v1/organizations/{organization_id}/dynamic_models/{id}' do
    let!(:model_definition) do
      definition = create(:dynamic_model_definition,
        organization: organization,
        name: 'TestModel',
        field_definitions_attributes: [
          {
            name: 'title',
            field_type: 'string',
            options: {
              required: true,
              default: '',
              validations: {
                presence: true
              }
            }
          }
        ]
      )
      @model_definition = definition
      DynamicModelService.new(definition).generate
      definition
    end

    let(:id) { model_definition.id }
    let(:organization_id) { organization.id }

    get 'Retrieves a dynamic model' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string

      response '200', 'dynamic model found' do
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json = json_response
          expect(json['data']['attributes']['name']).to eq('TestModel')
          expect(json['data']['attributes']['fields_attributes']).to be_present
        end
      end

      response '404', 'dynamic model not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end

    patch 'Updates a dynamic model' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      consumes 'application/json'
      parameter name: :organization_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string
      parameter name: :dynamic_model_definition, in: :body, schema: {
        type: :object,
        properties: {
          dynamic_model_definition: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string }
            }
          }
        }
      }

      response '200', 'dynamic model updated' do
        let(:dynamic_model_definition) do
          {
            dynamic_model_definition: {
              field_definitions_attributes: [
                {
                  name: 'new_field',
                  field_type: 'string',
                  options: {
                    required: true,
                    default: '',
                    validations: { presence: true }
                  }
                }
              ]
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          table_name = "org_#{organization.id}_test_models"
          expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be true

          # Check that the new field was added
          columns = ActiveRecord::Base.connection.columns(table_name).map(&:name)
          expect(columns).to include('new_field')
        end
      end

      response '422', 'invalid update' do
        let(:dynamic_model_definition) do
          {
            dynamic_model_definition: {
              field_definitions_attributes: [
                {
                  name: 'invalid_field',
                  field_type: 'invalid_type',
                  options: {
                    required: true
                  }
                }
              ]
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors']).to include("Unsupported field type: invalid_type")
        end
      end
    end

    delete 'Deletes a dynamic model' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      parameter name: :organization_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string

      response '204', 'dynamic model deleted' do
        run_test! do |response|
          expect(response).to have_http_status(:no_content)

          expect(DynamicModelDefinition.exists?(id)).to be false

          table_name = "org_#{organization.id}_test_models"
          expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be false

          expect(Object.const_defined?("Org#{organization.id}TestModel")).to be false

          expect(DynamicRoute.find_by(path: "/api/v1/org_#{organization.id}_test_models")).to be_nil
        end
      end

      response '404', 'dynamic model not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
