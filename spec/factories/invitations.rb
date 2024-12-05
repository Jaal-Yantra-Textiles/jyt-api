
FactoryBot.define do
  factory :invitation do
    email { Faker::Internet.email }
    status { "pending" }
    association :organization
  end
end
