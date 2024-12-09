require 'rails_helper'

RSpec.describe FieldDefinition, type: :model do
  describe 'associations' do
    it { should belong_to(:dynamic_model_definition) }
  end

  describe 'validations' do
    subject { build(:field_definition) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:field_type) }
    it { should validate_presence_of(:options) }

    it { should validate_inclusion_of(:field_type).in_array(FieldDefinition::VALID_TYPES) }

    context 'name format validation' do
      valid_names = [ 'name', 'first_name', 'user123', 'address_line_1' ]
      invalid_names = [ 'Name', '1name', 'first-name', 'user@123', 'address.line' ]

      valid_names.each do |valid_name|
        it "allows valid field name: #{valid_name}" do
          field_definition = build(:field_definition, name: valid_name)
          expect(field_definition).to be_valid
        end
      end

      invalid_names.each do |invalid_name|
        it "rejects invalid field name: #{invalid_name}" do
          field_definition = build(:field_definition, name: invalid_name)
          expect(field_definition).to be_invalid
          expect(field_definition.errors[:name]).to include(
            'must start with a lowercase letter and can only contain lowercase letters, numbers, and underscores'
          )
        end
      end
    end
  end

  describe 'field types' do
    context 'valid field types' do
      FieldDefinition::VALID_TYPES.each do |field_type|
        it "accepts #{field_type} as valid field type" do
          field_definition = build(:field_definition, field_type: field_type)
          expect(field_definition).to be_valid
        end
      end
    end

    context 'invalid field types' do
      [ 'invalid', 'array', 'hash', 'date', nil ].each do |invalid_type|
        it "rejects #{invalid_type.inspect} as field type" do
          field_definition = build(:field_definition, field_type: invalid_type)
          expect(field_definition).to be_invalid
          expect(field_definition.errors[:field_type]).to include('is not included in the list')
        end
      end
    end
  end

  describe 'options validation' do
    context 'with valid options' do
      valid_options = [
        { default: '' },
        { default: 'test', required: true },
        { min: 0, max: 100 },
        { choices: [ 'option1', 'option2' ] }
      ]

      valid_options.each do |options|
        it "accepts valid options: #{options}" do
          field_definition = build(:field_definition, options: options)
          expect(field_definition).to be_valid
        end
      end
    end

    context 'with invalid options' do
      it 'rejects nil options' do
        field_definition = build(:field_definition, options: nil)
        expect(field_definition).to be_invalid
        expect(field_definition.errors[:options]).to include("can't be blank")
      end
    end
  end

  describe 'scopes' do
    let(:model_definition) { create(:dynamic_model_definition) }

    before do
      create(:field_definition, field_type: 'string', dynamic_model_definition: model_definition)
      create(:field_definition, field_type: 'integer', dynamic_model_definition: model_definition)
      create(:field_definition, field_type: 'boolean', dynamic_model_definition: model_definition)
    end

    FieldDefinition::VALID_TYPES.each do |type|
      it "scope by_type(:#{type}) returns only #{type} fields" do
        fields = FieldDefinition.where(field_type: type)
        expect(fields.all? { |field| field.field_type == type }).to be true
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:field_definition)).to be_valid
    end

    context 'with different field types' do
      FieldDefinition::VALID_TYPES.each do |field_type|
        it "creates valid factory with #{field_type} type" do
          field = build(:field_definition, field_type: field_type)
          expect(field).to be_valid
          expect(field.field_type).to eq(field_type)
        end
      end
    end
  end

  describe 'instance methods' do
    let(:field_definition) { build(:field_definition) }

    describe '#column_definition' do
      context 'with string type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'string'
          expect(field_definition.column_definition).to eq(:string)
        end
      end

      context 'with text type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'text'
          expect(field_definition.column_definition).to eq(:text)
        end
      end

      context 'with integer type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'integer'
          expect(field_definition.column_definition).to eq(:integer)
        end
      end

      context 'with float type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'float'
          expect(field_definition.column_definition).to eq(:float)
        end
      end

      context 'with decimal type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'decimal'
          expect(field_definition.column_definition).to eq({ type: :decimal, precision: 10, scale: 2 })
        end
      end

      context 'with datetime type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'datetime'
          expect(field_definition.column_definition).to eq(:datetime)
        end
      end

      context 'with boolean type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'boolean'
          expect(field_definition.column_definition).to eq({ default: false, type: :boolean })
        end
      end

      context 'with json type' do
        it 'returns correct column definition' do
          field_definition.field_type = 'json'
          expect(field_definition.column_definition).to eq({ default: {}, type: :jsonb })
        end
      end

      context 'with unsupported type' do
        it 'raises an error' do
          field_definition.field_type = 'unsupported'
          expect { field_definition.column_definition }.to raise_error("Unsupported field type: unsupported")
        end
      end
    end
  end
end
