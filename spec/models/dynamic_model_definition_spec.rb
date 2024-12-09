require 'rails_helper'

RSpec.describe DynamicModelDefinition, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:field_definitions).dependent(:destroy) }
    it { should have_many(:relationship_definitions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:dynamic_model_definition) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:organization) }

    context 'name format validation' do
      valid_names = [ 'User', 'TaskList', 'ProjectManager', 'CustomField123' ]
      invalid_names = [ '123User', 'task-list', 'project_manager', 'Custom Field' ]

      valid_names.each do |valid_name|
        it "allows valid model name: #{valid_name}" do
          model_definition = build(:dynamic_model_definition, name: valid_name)
          expect(model_definition).to be_valid
        end
      end

      invalid_names.each do |invalid_name|
        it "rejects invalid model name: #{invalid_name}" do
          model_definition = build(:dynamic_model_definition, name: invalid_name)
          expect(model_definition).to be_invalid
          expect(model_definition.errors[:name]).to include(
            'must start with an uppercase letter and can only contain letters and numbers'
          )
        end
      end
    end

    context 'name uniqueness' do
      it 'validates uniqueness of name within organization scope' do
        organization = create(:organization)
        create(:dynamic_model_definition, name: 'TestModel', organization: organization)

        duplicate_model = build(:dynamic_model_definition, name: 'TestModel', organization: organization)
        expect(duplicate_model).to be_invalid
        expect(duplicate_model.errors[:name]).to include('has already been taken')
      end

      it 'allows same name in different organizations' do
        org1 = create(:organization)
        org2 = create(:organization)

        create(:dynamic_model_definition, name: 'TestModel', organization: org1)
        model2 = build(:dynamic_model_definition, name: 'TestModel', organization: org2)

        expect(model2).to be_valid
      end
    end
  end

  describe 'nested attributes' do
    it { should accept_nested_attributes_for(:field_definitions).allow_destroy(true) }
    it { should accept_nested_attributes_for(:relationship_definitions).allow_destroy(true) }

    it 'creates model with nested field definitions' do
      model_definition = create(:dynamic_model_definition, :with_fields)
      expect(model_definition.field_definitions).to be_present
    end

    it 'creates model with nested relationship definitions' do
      model_definition = create(:dynamic_model_definition, :with_relationships)
      expect(model_definition.relationship_definitions).to be_present
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'strips whitespace from name' do
        model = build(:dynamic_model_definition, name: ' TestModel ')
        model.valid?
        expect(model.name).to eq('TestModel')
      end
    end
  end

  describe 'instance methods' do
    let(:model_definition) { create(:dynamic_model_definition, :with_fields, :with_relationships) }

    describe '#table_name' do
      it 'returns the correct table name for the dynamic model' do
        expect(model_definition.table_name).to eq(
          "org_#{model_definition.organization_id}_#{model_definition.name.underscore.pluralize}"
        )
      end
    end

    describe '#field_names' do
      it 'returns an array of field names' do
        field_names = model_definition.field_names
        expect(field_names).to be_an(Array)
        expect(field_names).to include(model_definition.field_definitions.first.name)
      end
    end

    describe '#relationship_names' do
      it 'returns an array of relationship names' do
        relationship_names = model_definition.relationship_names
        expect(relationship_names).to be_an(Array)
        expect(relationship_names).to include(model_definition.relationship_definitions.first.name)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:dynamic_model_definition)).to be_valid
    end

    it 'has a valid factory with fields' do
      model = create(:dynamic_model_definition, :with_fields)
      expect(model).to be_valid
      expect(model.field_definitions).not_to be_empty
    end

    it 'has a valid factory with relationships' do
      model = create(:dynamic_model_definition, :with_relationships)
      expect(model).to be_valid
      expect(model.relationship_definitions).not_to be_empty
    end

    it 'has a valid factory with both fields and relationships' do
      model = create(:dynamic_model_definition, :with_fields, :with_relationships)
      expect(model).to be_valid
      expect(model.field_definitions).not_to be_empty
      expect(model.relationship_definitions).not_to be_empty
    end
  end
end
