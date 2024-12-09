FactoryBot.define do
  factory :relationship_definition do
    sequence(:name) { |n| "relationship_#{n}" }
    relationship_type { 'belongs_to' } # Default to a valid type
    target_model { 'Target' }
    options { {} }

    trait :belongs_to do
      relationship_type { 'belongs_to' }
    end

    trait :has_many do
      relationship_type { 'has_many' }
    end

    trait :has_one do
      relationship_type { 'has_one' }
    end
  end
end
