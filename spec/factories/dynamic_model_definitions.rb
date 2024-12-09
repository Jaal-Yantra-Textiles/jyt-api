# spec/factories/dynamic_model_definitions.rb
FactoryBot.define do
  factory :dynamic_model_definition do
    sequence(:name) { |n| "Model#{n}" }
    association :organization

    trait :with_fields do
      after(:build) do |model|
        model.field_definitions_attributes = [
          {
            name: "title",
            field_type: "string",
            options: {
              max_length: 255,
              required: true
            }
          },
          {
            name: "description",
            field_type: "text",
            options: {
              required: false,
              default: ""
            }
          },
          {
            name: "amount",
            field_type: "decimal",
            options: {
              precision: 10,
              scale: 2,
              min: 0,
              required: true
            }
          },
          {
            name: "active",
            field_type: "boolean",
            options: {
              default: false,
              required: true
            }
          }
        ]
      end
    end

    trait :with_relationships do
      after(:build) do |model|
        model.relationship_definitions_attributes = [
          {
            name: "owner",
            relationship_type: "belongs_to",
            target_model: "User"
          },
          {
            name: "comments",
            relationship_type: "has_many",
            target_model: "Comment"
          }
        ]
      end
    end
  end
end
