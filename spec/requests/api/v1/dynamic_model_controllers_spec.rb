require 'rails_helper'


RSpec.describe ' Api::V1::DynamicModelsController', type: :request do
  include_context 'dynamic model context'

  let(:user) { create(:user) }
  let(:auth_token) { auth_headers(user)[:Authorization] }

  describe 'POST /api/v1/dynamic_models' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          model: {
            name: 'Project',
            fields_attributes: [
              {
                name: 'title',
                field_type: 'string',
                options: {
                  nullable: false,
                  filterable: true,
                  index: true,
                  validations: {
                    presence: true,
                    length: { maximum: 100 }
                  }
                }
              }
            ]
          }
        }
      end

      it 'creates a new dynamic model' do
        expect {
          post '/api/v1/dynamic_models',
               params: valid_params,
               headers: { 'Authorization' => auth_token }
        }.to change(DynamicModelDefinition, :count).by(1)
          .and change(FieldDefinition, :count).by(1)
      end

      it 'returns a 201 status' do
        post '/api/v1/dynamic_models',
             params: valid_params,
             headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:created)
      end

      it 'returns the created model definition' do
        post '/api/v1/dynamic_models',
             params: valid_params,
             headers: { 'Authorization' => auth_token }

        json = JSON.parse(response.body)
        expect(json['data']['attributes']['name']).to eq('Project')
        expect(json['data']['attributes']['fields_attributes'].length).to eq(1)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          model: {
            name: '',  # Invalid: empty name
            fields_attributes: []
          }
        }
      end

      it 'does not create a new dynamic model' do
        expect {
          post '/api/v1/dynamic_models',
               params: invalid_params,
               headers: { 'Authorization' => auth_token }
        }.not_to change(DynamicModelDefinition, :count)
      end

      it 'returns a 422 status' do
        post '/api/v1/dynamic_models',
             params: invalid_params,
             headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
