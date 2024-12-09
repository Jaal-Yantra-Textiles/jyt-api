# spec/services/dynamic_model_loader_spec.rb
require 'rails_helper'

RSpec.describe DynamicModelLoader do
  let(:organization) { create(:organization) }

  # Helper method to create the database table
  def create_table(model_definition)
    fields = model_definition.field_definitions.map do |field|
      sql_type = case field.field_type
      when "string"  then "VARCHAR"
      when "text"    then "TEXT"
      when "integer" then "INTEGER"
      when "float"   then "DOUBLE PRECISION"
      when "decimal" then "NUMERIC(10, 2)"
      when "datetime" then "TIMESTAMP"
      when "boolean" then "BOOLEAN DEFAULT FALSE"
      when "json"    then "JSONB DEFAULT '{}'"
      end
      "#{field.name} #{sql_type}"
    end.join(",\n")

    table_name = "org_#{model_definition.organization_id}_#{model_definition.name.underscore.pluralize}"

    ActiveRecord::Base.connection.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS #{table_name} (
        id SERIAL PRIMARY KEY,
        #{fields},
        organization_id INTEGER NOT NULL,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      );
    SQL
  end

  # Helper method to drop the table
  def drop_table(model_definition)
    table_name = "org_#{model_definition.organization_id}_#{model_definition.name.underscore.pluralize}"
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table_name} CASCADE")
  end

  describe '.load_model' do
    context 'with basic model definition' do
      let(:dynamic_model_definition) do
        create(:dynamic_model_definition,
          name: 'SimpleModel',
          organization: organization,
          field_definitions: [
            build(:field_definition, :required,
              name: 'title',
              field_type: 'string'
            )
          ]
        )
      end

      before do
        create_table(dynamic_model_definition)
      end

      after do
        drop_table(dynamic_model_definition)
      end

      it 'creates a valid model class' do
        klass = described_class.load_model(dynamic_model_definition)
        expect(Object.const_defined?(klass.name)).to be true
      end

      it 'sets up the table name correctly' do
        klass = described_class.load_model(dynamic_model_definition)
        expected_table_name = "org_#{organization.id}_simple_models"
        expect(klass.table_name).to eq(expected_table_name)
      end
    end

    context 'with field validations' do
      let(:dynamic_model_definition) do
        create(:dynamic_model_definition,
          name: 'ValidationModel',
          organization: organization,
          field_definitions: [
            build(:field_definition, :required,
              name: 'required_field',
              field_type: 'string'
            ),
            build(:field_definition, :numeric,
              name: 'number_field',
              field_type: 'integer'
            ),
            build(:field_definition, :optional,
              name: 'optional_field',
              field_type: 'string'
            )
          ]
        )
      end

      before do
        create_table(dynamic_model_definition)
      end

      after do
        drop_table(dynamic_model_definition)
      end

      let(:klass) { described_class.load_model(dynamic_model_definition) }

      it 'sets up presence validation' do
        instance = klass.new
        instance.valid?
        expect(instance.errors[:required_field]).to include("can't be blank")
      end

      it 'sets up numericality validation' do
        instance = klass.new(
          required_field: 'present',
          number_field: 'not a number',
          organization_id: organization.id
        )
        instance.valid?
        expect(instance.errors[:number_field]).to include("is not a number")
      end

      it 'allows optional fields to be nil' do
        instance = klass.new(
          required_field: 'present',
          organization_id: organization.id
        )
        expect(instance.valid?).to be true
      end
    end

    context 'with relationships' do
        let(:parent_model_definition) do
          create(:dynamic_model_definition,
            name: 'Parent',
            organization: organization,
            field_definitions: [
              build(:field_definition, :required, name: 'name')
            ]
          )
        end

        let(:child_model_definition) do
          create(:dynamic_model_definition,
            name: 'Child',
            organization: organization,
            field_definitions: [
              build(:field_definition, :required, name: 'title')
            ],
            relationship_definitions: [
              build(:relationship_definition,
                name: 'parent',
                relationship_type: 'belongs_to',
                target_model: 'Parent'
              )
            ]
          )
        end

        before do
          create_table(parent_model_definition)
          create_table(child_model_definition)
          # First load the parent model
          described_class.load_model(parent_model_definition)
          # Then load the child model to establish the belongs_to relationship
          described_class.load_model(child_model_definition)
        end

        after do
          drop_table(child_model_definition)
          drop_table(parent_model_definition)
        end

        it 'sets up belongs_to relationship' do
          child_class = described_class.load_model(child_model_definition)
          association = child_class.reflect_on_association(:parent)
          expect(association).to be_present
          expect(association.macro).to eq(:belongs_to)
        end

        it 'sets up has_many relationship' do
          # Create a new definition for parent with has_many relationship
          updated_parent = parent_model_definition
          updated_parent.relationship_definitions = [
            build(:relationship_definition,
              name: 'children',
              relationship_type: 'has_many',
              target_model: 'Child'
            )
          ]

          # Load the updated parent model
          parent_class = described_class.load_model(updated_parent)
          association = parent_class.reflect_on_association(:children)
          expect(association).to be_present
          expect(association.macro).to eq(:has_many)
        end
      end

      context 'with errors' do
        let(:model_with_valid_fields) do
          create(:dynamic_model_definition,
            name: 'ValidFields',
            organization: organization,
            field_definitions: [
              build(:field_definition, :required, name: 'name')
            ]
          )
        end

        before do
          create_table(model_with_valid_fields)
          described_class.load_model(model_with_valid_fields)
        end

        after do
          drop_table(model_with_valid_fields)
        end

        it 'raises ModelLoadError for non-existent target model' do
          invalid_model = build(:dynamic_model_definition,
            name: 'InvalidRelation',
            organization: organization,
            field_definitions: [
              build(:field_definition, :required, name: 'name')
            ],
            relationship_definitions: [
              build(:relationship_definition,
                name: 'invalid',
                relationship_type: 'belongs_to',
                target_model: 'NonExistentModel'
              )
            ]
          )

          create_table(invalid_model)

          begin
            expect {
              described_class.load_model(invalid_model)
            }.to raise_error(DynamicModelLoader::ModelLoadError, /Target model.*does not exist/)
          ensure
            drop_table(invalid_model)
          end
        end

        it 'raises ModelLoadError for invalid relationship configuration' do
          # Instead of creating an invalid relationship type in the factory,
          # we'll test the validation in the loader itself
          allow_any_instance_of(RelationshipDefinition)
            .to receive(:relationship_type)
            .and_return('invalid_type')

          invalid_model = build(:dynamic_model_definition,
            name: 'InvalidType',
            organization: organization,
            field_definitions: [
              build(:field_definition, :required, name: 'name')
            ],
            relationship_definitions: [
              build(:relationship_definition,
                name: 'invalid',
                relationship_type: 'belongs_to', # This will be overridden by the stub above
                target_model: 'ValidFields'
              )
            ]
          )

          create_table(invalid_model)

          begin
            expect {
              described_class.load_model(invalid_model)
            }.to raise_error(DynamicModelLoader::ModelLoadError, /Invalid relationship: Target model 'ValidFields'/)
          ensure
            drop_table(invalid_model)
          end
        end
      end
  end

  describe '.unload_model' do
    let(:dynamic_model_definition) do
      create(:dynamic_model_definition,
        name: 'UnloadTest',
        organization: organization,
        field_definitions: [ build(:field_definition, :required) ]
      )
    end

    before do
      create_table(dynamic_model_definition)
      described_class.load_model(dynamic_model_definition)
    end

    after do
      drop_table(dynamic_model_definition)
    end

    it 'removes the constant' do
      class_name = "Org#{organization.id}UnloadTest"
      expect {
        described_class.unload_model(class_name)
      }.to change {
        Object.const_defined?(class_name)
      }.from(true).to(false)
    end
  end
end
