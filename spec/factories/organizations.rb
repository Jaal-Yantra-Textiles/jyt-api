
FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    industry { Faker::Company.industry }
    active { true }
    association :owner, factory: :user
  end
end
