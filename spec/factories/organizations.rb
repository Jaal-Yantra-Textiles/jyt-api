FactoryBot.define do
  factory :organization do
    name { "MyString" }
    industry { "MyString" }
    association :owner, factory: :user
  end
end
