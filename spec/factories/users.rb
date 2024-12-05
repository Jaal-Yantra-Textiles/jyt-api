FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    role { 'customer' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_oauth do
      oauth_provider { 'google_oauth2' }
      oauth_token { SecureRandom.hex(32) }
      oauth_expires_at { 1.hour.from_now }
      password { nil }
      password_confirmation { nil }
    end

    trait :with_facebook do
      oauth_provider { 'facebook' }
      oauth_token { SecureRandom.hex(32) }
      oauth_expires_at { 1.hour.from_now }
      password { nil }
      password_confirmation { nil }
    end
  end
end
