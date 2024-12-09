require 'rails_helper'

RSpec.describe DynamicModelService do
  let(:organization) { create(:organization) }
  let(:dynamic_model_definition) do
    create(:dynamic_model_definition,
      name: 'Product',
      organization: organization,
      field_definitions: [
        build(:field_definition, :required, name: 'name')
      ]
    )
  end
  let(:service) { described_class.new(dynamic_model_definition) }
  let(:base_route_path) { "/api/v1/org_#{organization.id}_products" }

  describe 'route management' do
    before do
      allow(Rails.application).to receive(:reload_routes!)
    end

    describe '#store_routes_in_db' do
      context 'when creating CRUD routes' do
        before { service.send(:store_routes_in_db) }

        let(:routes) { DynamicRoute.where(organization_id: organization.id) }

        it 'creates all required routes' do
          expect(routes.count).to eq(6)
        end

        it 'creates correct index route' do
          route = routes.find_by(action: 'index')

          expect(route).to have_attributes(
            path: base_route_path,
            method: 'GET',
            controller: "api/v1/org_#{organization.id}_products"
          )
        end

        it 'creates correct show route' do
          route = routes.find_by(action: 'show')

          expect(route).to have_attributes(
            path: "#{base_route_path}/:id",
            method: 'GET'
          )
        end

        it 'creates correct create route' do
          route = routes.find_by(action: 'create')

          expect(route).to have_attributes(
            path: base_route_path,
            method: 'POST'
          )
        end

        it 'creates correct update routes' do
          update_routes = routes.where(action: 'update')

          aggregate_failures do
            expect(update_routes.count).to eq(2)
            expect(update_routes.pluck(:method)).to contain_exactly('PUT', 'PATCH')
            expect(update_routes.pluck(:path).uniq).to eq([ "#{base_route_path}/:id" ])
          end
        end

        it 'creates correct destroy route' do
          route = routes.find_by(action: 'destroy')

          expect(route).to have_attributes(
            path: "#{base_route_path}/:id",
            method: 'DELETE'
          )
        end
      end

      context 'with invalid path' do
        before do
          allow(service).to receive(:build_resource_path).and_return('invalid_path')
        end

        it 'raises an error' do
          expect {
            service.send(:store_routes_in_db)
          }.to raise_error(DynamicModel::RouteError, /must start with '\//)
        end
      end

      context 'when updating existing routes' do
        it 'maintains the same number of routes' do
          service.send(:store_routes_in_db)
          initial_count = DynamicRoute.count

          service.send(:store_routes_in_db)

          expect(DynamicRoute.count).to eq(initial_count)
        end
      end
    end

    describe '#delete_routes_from_db' do
      before { service.send(:store_routes_in_db) }

      it 'removes all routes for the model' do
        expect {
          service.send(:delete_routes_from_db)
        }.to change { DynamicRoute.count }.by(-6)
      end

      context 'with multiple models' do
        let(:other_model) do
          create(:dynamic_model_definition,
            name: 'Category',
            organization: organization
          )
        end

        before do
          other_service = described_class.new(other_model)
          other_service.send(:store_routes_in_db)
        end

        it 'only deletes routes for the specified model' do
          initial_count = DynamicRoute.count

          service.send(:delete_routes_from_db)

          aggregate_failures do
            expect(DynamicRoute.count).to eq(initial_count - 6)
            expect(DynamicRoute.pluck(:path)).to all(include('categories'))
          end
        end
      end
    end

    describe 'model updates' do
      before { service.generate }

      context 'when attempting to change model name' do
        it 'raises an error' do
          expect {
            service.update(name: 'UpdatedProduct')
          }.to raise_error(DynamicModel::ValidationError, "Changing model name is not supported after creation")
        end
      end

      context 'when updating other attributes' do
        it 'allows updates to non-name attributes' do
          expect {
            service.update(description: 'Updated description')
          }.not_to raise_error
        end
      end
    end
  end
end
