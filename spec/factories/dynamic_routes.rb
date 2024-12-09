FactoryBot.define do
  factory :dynamic_route do
    path { "MyString" }
    controller { "MyString" }
    action { "MyString" }
    add_attribute(:method) { "GET" }
    organization_id { 1 }
  end
end
