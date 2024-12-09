require 'swagger_helper'

RSpec.describe 'Api::V1::DynamicModelControllerAdapter', type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, owner: user, members: [ user ]) }
  let(:Authorization) { auth_headers(user)[:Authorization] }

  # Shared context for dynamic model setup
  let(:dynamic_model_definition) do
    definition = create(:dynamic_model_definition, :with_fields,
                       name: 'Project',
                       organization: organization)
    DynamicModelService.new(definition).send(:ensure_table_exists)
    definition
  end

  let(:model_name) { dynamic_model_definition.name.underscore }
  let(:model_class) { DynamicModelLoader.load_model(dynamic_model_definition) }

  # Valid attributes that match all required validations
  let(:valid_attributes) do
    {
      title: "Sample Project",
      description: "A sample project description",
      amount: 100.00,  # Valid decimal number
      active: true     # Required boolean
    }
  end

  shared_examples 'returns 404 for invalid model' do
    response '404', 'dynamic model not found' do
      let(:model_name) { 'nonexistent' }

      run_test! do |response|
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  shared_examples 'returns 404 for invalid record' do
    response '404', 'record not found' do
      let(:id) { 'invalid' }

      run_test! do |response|
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  path '/api/v1/dynamic_model/{model_name}' do
    parameter name: :model_name, in: :path, type: :string, description: 'Name of the dynamic model'

    get 'Lists all records for a dynamic model' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      produces 'application/json'

      response '200', 'records found' do
        let(:model_name) { dynamic_model_definition.name.underscore }

        before do
          # Create with all required attributes
          model_class.create!(valid_attributes)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(1)
          expect(json['data'].first['title']).to eq('Sample Project')
          expect(json['data'].first['amount'].to_f).to eq(100.00)
          expect(json['data'].first['active']).to eq(true)
        end
      end

      include_examples 'returns 404 for invalid model'
    end

    post 'Creates a record for a dynamic model' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      consumes 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              amount: { type: :number },
              active: { type: :boolean }
            },
            required: [ 'title', 'amount', 'active' ]
          }
        }
      }

      response '201', 'record created' do
        let(:model_name) { dynamic_model_definition.name.underscore }
        let(:body) { { project: valid_attributes } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:created)
          expect(json['data']['title']).to eq('Sample Project')
          expect(json['data']['amount'].to_f).to eq(100.00)
          expect(json['data']['active']).to eq(true)
        end
      end

      response '422', 'validation errors' do
        let(:model_name) { dynamic_model_definition.name.underscore }
        let(:body) { { project: { title: 'Sample Project' } } } # Missing required fields

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json['errors']).to include("Amount can't be blank")
          expect(json['errors']).to include("Active can't be blank")
        end
      end

      include_examples 'returns 404 for invalid model'
    end
  end

  path '/api/v1/dynamic_model/{model_name}/{id}' do
    parameter name: :model_name, in: :path, type: :string, description: 'Name of the dynamic model'
    parameter name: :id, in: :path, type: :string, description: 'ID of the record'

    get 'Retrieves a specific record' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      produces 'application/json'

      response '200', 'record found' do
        let(:id) { model_class.create!(valid_attributes).id }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['title']).to eq(valid_attributes[:title])
          expect(json['data']['amount']).to eq(valid_attributes[:amount].to_s)
          expect(json['data']['active']).to eq(valid_attributes[:active])
        end
      end

      include_examples 'returns 404 for invalid record'
    end

    put 'Updates a specific record' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]
      consumes 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              amount: { type: :number },
              active: { type: :boolean }
            }
          }
        }
      }

      response '200', 'record updated' do
        let(:id) { model_class.create!(valid_attributes).id }
        let(:body) { { project: { title: "Updated Title", amount: 200.50 } } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['title']).to eq("Updated Title")
          expect(json['data']['amount']).to eq("200.5")
          # Unchanged attributes should remain the same
          expect(json['data']['active']).to eq(valid_attributes[:active])
        end
      end

      context 'with invalid updates' do
        let(:id) { model_class.create!(valid_attributes).id }

        response '422', 'invalid amount' do
          let(:body) { { project: { amount: -1 } } }

          run_test! do |response|
            json = JSON.parse(response.body)
            expect(json['errors']).to include("Amount must be greater than or equal to 0.0")
          end
        end

        response '422', 'title too long' do
          let(:body) { { project: { title: "a" * 256 } } }

          run_test! do |response|
            json = JSON.parse(response.body)
            expect(json['errors']).to include("Title is too long (maximum is 255 characters)")
          end
        end

        response '422', 'setting required field to null' do
          let(:body) { { project: { title: nil } } }

          run_test! do |response|
            json = JSON.parse(response.body)
            expect(json['errors']).to include("Title can't be blank")
          end
        end
      end

      include_examples 'returns 404 for invalid record'
    end

    delete 'Deletes a specific record' do
      tags 'Dynamic Models'
      security [ bearer_auth: [] ]

      response '204', 'record deleted' do
        let(:id) { model_class.create!(valid_attributes).id }

        run_test! do |response|
          expect(response).to have_http_status(:no_content)
          expect(model_class.exists?(id)).to be false
        end
      end

      include_examples 'returns 404 for invalid record'
    end
  end
end
