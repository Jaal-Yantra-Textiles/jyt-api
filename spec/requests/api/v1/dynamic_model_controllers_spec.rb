require 'rails_helper'

RSpec.describe 'Api::V1::DynamicModelsController', type: :request do
  include_context 'dynamic model context'

  let(:user) { create(:user) }
  let(:organization) { create(:organization, owner: user, members: [ user ]) }
  let(:auth_token) { auth_headers(user)[:Authorization] }

  before { organization }

  after(:each) do
    # Clean up dynamically created database tables
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS org_#{organization.id}_projects CASCADE")

    # Clean up dynamically generated model and controller files
    model_path = Rails.root.join("app/models/org_#{organization.id}_project.rb")
    controller_path = Rails.root.join("app/controllers/api/v1/org_#{organization.id}_projects_controller.rb")
    File.delete(model_path) if File.exist?(model_path)
    File.delete(controller_path) if File.exist?(controller_path)
  end

  after(:all) do
    # Reload application to clear dynamically loaded classes
    Rails.application.eager_load!
  end

  describe 'POST /api/v1/dynamic_models' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          organization_id: organization.id,
          dynamic_model_definition: {
            name: 'Project',
            field_definitions_attributes: [
              {
                name: 'title',
                field_type: 'string',
                options: {
                  nullable: false,
                  filterable: true,
                  index: true,
                  validations: {
                    presence: true,
                    length: { maximum: 100, minimum: 5 }
                  }
                }
              }
            ],
            relationship_definitions_attributes: [
              {
                name: 'owner',
                relationship_type: 'belongs_to',
                target_model: 'User'
              },
              {
                name: 'organizations',
                relationship_type: 'has_many',
                target_model: 'Organization'
              }
            ]
          }
        }
      end
      it 'creates a new dynamic model with fields and relationships' do
        expect {
          post '/api/v1/dynamic_models',
               params: valid_params,
               headers: { 'Authorization' => auth_token }
        }.to change(DynamicModelDefinition, :count).by(1)
          .and change(FieldDefinition, :count).by(1)
          .and change(RelationshipDefinition, :count).by(2)
      end

      it 'assigns the correct organization' do
        post '/api/v1/dynamic_models',
             params: valid_params,
             headers: { 'Authorization' => auth_token }
        expect(DynamicModelDefinition.last.organization).to eq(organization)
      end

      it 'generates the model files' do
        post '/api/v1/dynamic_models',
             params: valid_params,
             headers: { 'Authorization' => auth_token }

        model_path = Rails.root.join("app/models/org_#{organization.id}_project.rb")
        controller_path = Rails.root.join("app/controllers/api/v1/org_#{organization.id}_projects_controller.rb")

        expect(File.exist?(model_path)).to be true
        expect(File.exist?(controller_path)).to be true
      end

      it 'returns the created model definition' do
        post '/api/v1/dynamic_models',
             params: valid_params,
             headers: { 'Authorization' => auth_token }

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:created)
        expect(json['data']['attributes']['name']).to eq('Project')
        expect(json['data']['attributes']['organization_id']).to eq(organization.id)
        expect(json['data']['attributes']['fields_attributes'].length).to eq(1)
        expect(json['data']['attributes']['relationship_definitions_attributes'].length).to eq(2)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          organization_id: organization.id,
          dynamic_model_definition: {
            name: '',
            field_definitions_attributes: [],
            relationship_definitions_attributes: []
          }
        }
      end

      it 'does not create a dynamic model' do
        expect {
          post '/api/v1/dynamic_models',
               params: invalid_params,
               headers: { 'Authorization' => auth_token }
        }.not_to change(DynamicModelDefinition, :count)
      end

      it 'returns errors' do
        post '/api/v1/dynamic_models',
             params: invalid_params,
             headers: { 'Authorization' => auth_token }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
