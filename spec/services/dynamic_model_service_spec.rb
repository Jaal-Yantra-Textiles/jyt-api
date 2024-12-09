# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DynamicModelService do
  let(:organization) { create(:organization) }

  # Category model definition and service
  let(:category_field_definitions) do
    [
      build(:field_definition, name: 'name', field_type: 'string'),
      build(:field_definition, name: 'description', field_type: 'text')
    ]
  end

  let(:category_model_definition) do
    create(:dynamic_model_definition,
      name: 'Category',
      organization: organization,
      field_definitions: category_field_definitions
    )
  end

  let(:category_service) { described_class.new(category_model_definition) }

  # Product model definition and service
  let(:product_field_definitions) do
    [
      build(:field_definition, name: 'title', field_type: 'string'),
      build(:field_definition, name: 'description', field_type: 'text'),
      build(:field_definition, name: 'price', field_type: 'decimal')
    ]
  end

  let(:product_relationship_definitions) do
    [
      build(:relationship_definition,
        name: 'category',
        relationship_type: 'belongs_to',
        target_model: 'Category'
      )
    ]
  end

  let(:product_model_definition) do
    create(:dynamic_model_definition,
      name: 'Product',
      organization: organization,
      field_definitions: product_field_definitions,
      relationship_definitions: product_relationship_definitions
    )
  end

  let(:service) { described_class.new(product_model_definition) }

  # Shared setup
  before do
    allow(Rails.application).to receive(:reload_routes!)
  end

  describe '#initialize' do
    context 'with valid model definition' do
      it 'initializes successfully' do
        expect { service }.not_to raise_error
      end
    end

    context 'with invalid model definition' do
      context 'when name is blank' do
        let(:product_model_definition) { build(:dynamic_model_definition, name: '', organization: organization) }

        it 'raises ValidationError' do
          expect { service }
            .to raise_error(DynamicModel::ValidationError, 'Model name cannot be blank')
        end
      end

      context 'when organization_id is blank' do
        let(:product_model_definition) { build(:dynamic_model_definition, name: 'Product', organization_id: nil) }

        it 'raises ValidationError' do
          expect { service }
            .to raise_error(DynamicModel::ValidationError, 'Organization ID cannot be blank')
        end
      end
    end
  end

  describe '#generate' do
    context 'when generating dependent models' do
      it 'creates models in the correct order' do
        # First create the category model
        expect { category_service.generate }.not_to raise_error
        expect(ActiveRecord::Base.connection.table_exists?(category_service.send(:table_name))).to be true

        # Then create the product model
        expect { service.generate }.not_to raise_error
        expect(ActiveRecord::Base.connection.table_exists?(service.send(:table_name))).to be true
      end

      it 'sets up the relationship correctly' do
        category_service.generate
        service.generate

        # Verify the foreign key exists
        foreign_keys = ActiveRecord::Base.connection.foreign_keys(service.send(:table_name))
        category_table = category_service.send(:table_name)

        expect(foreign_keys.any? { |fk| fk.to_table == category_table }).to be true
      end

      it 'allows creating records with the relationship' do
        category_service.generate
        service.generate

        # Get the generated model classes
        category_class = Object.const_get(category_service.send(:class_name))
        product_class = Object.const_get(service.send(:class_name))

        puts "Product class relationships: #{product_class.reflect_on_all_associations.map(&:name)}"
        puts "Product class belongs_to associations: #{product_class.reflect_on_all_associations(:belongs_to).map(&:name)}"

        # Create related records
        category = category_class.create!(
          name: 'Test Category',
          organization_id: organization.id
        )

        product = product_class.create!(
          title: 'Test Product',
          price: 99.99,
          category_id: category.id,
          organization_id: organization.id
        )

        puts "Product attributes: #{product.attributes}"
        puts "Product responds to category?: #{product.respond_to?(:category)}"
        puts "Product category_id: #{product.category_id}"

        expect(product.category).to eq(category)
      end
    end

    context 'when dependent model does not exist' do
      before do
        # Don't create the category model
      end

      it 'raises an error when trying to create product' do
        expect { service.generate }
          .to raise_error(DynamicModel::TableOperationError)
      end
    end
  end

  describe '#cleanup' do
    before do
      category_service.generate
      service.generate
    end

    it 'removes models in the correct order' do
      # First remove the product (dependent) model
      expect { service.cleanup }.not_to raise_error
      expect(ActiveRecord::Base.connection.table_exists?(service.send(:table_name))).to be false

      # Then remove the category model
      expect { category_service.cleanup }.not_to raise_error
      expect(ActiveRecord::Base.connection.table_exists?(category_service.send(:table_name))).to be false
    end

    it 'handles foreign key constraints properly' do
      service.cleanup

      # Verify no orphaned foreign keys
      remaining_foreign_keys = ActiveRecord::Base.connection
        .foreign_keys(category_service.send(:table_name))
        .select { |fk| fk.from_table == service.send(:table_name) }

      expect(remaining_foreign_keys).to be_empty
    end
  end

  describe '#update' do
    before do
      category_service.generate
      service.generate
    end

    context 'when updating relationship definition' do
      let(:new_relationship_definitions) do
        [
          build(:relationship_definition,
            name: 'category',
            relationship_type: 'belongs_to',
            target_model: 'Category',
            options: { optional: true }
          )
        ]
      end

      it 'updates the relationship without breaking foreign keys' do
        expect {
          service.update(relationship_definitions: new_relationship_definitions)
        }.not_to raise_error

        # Verify the foreign key still exists
        foreign_keys = ActiveRecord::Base.connection.foreign_keys(service.send(:table_name))
        category_table = category_service.send(:table_name)

        expect(foreign_keys.any? { |fk| fk.to_table == category_table }).to be true
      end
    end

    after do
      service.cleanup
      category_service.cleanup
    end
  end

  # Helper method for checking table structure
  def table_has_column?(table_name, column_name)
    ActiveRecord::Base.connection.column_exists?(table_name, column_name)
  end
end
