FactoryBot.define do
  factory :asset do
    organization
    association :created_by, factory: :user
    name { "test-#{SecureRandom.hex(4)}.pdf" }
    content_type { 'application/pdf' }
    byte_size { 1024 }
    storage_provider { 's3' }
    storage_key { "test/#{name}" }
    storage_path { "https://s3.amazonaws.com/bucket/test/#{name}" }
    metadata { { original_name: name } }
  end
end
