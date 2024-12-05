
FactoryBot.define do
  factory :social_account do
    user
    provider { %w[google_oauth2 facebook twitter].sample }
    sequence(:uid) { |n| "uid#{n}" }
  end
end
