FactoryBot.define do
  factory :field_definition do
    sequence(:name) { |n| "field_#{n}" }
    field_type { 'string' }
    options { { validations: { presence: false } } }
    dynamic_model_definition

    trait :required do
      options { { validations: { presence: true } } }
    end

    trait :string_type do
      field_type { 'string' }
    end

    trait :decimal_type do
      field_type { 'decimal' }
    end

    trait :text_type do
      field_type { 'text' }
    end

    trait :integer_type do
      field_type { 'integer' }
    end

    trait :numeric do
      field_type { 'integer' }
      options { { validations: { numericality: true } } }
    end

    trait :optional do
      options { { validations: { presence: false } } }
    end
  end
end
