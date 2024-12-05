# app/models/asset.rb
class Asset < ApplicationRecord
  belongs_to :organization
  belongs_to :created_by, class_name: "User"

  enum :storage_provider,  s3: 0, distributed: 1

  validates :name, presence: true
  validates :content_type, presence: true
  validates :byte_size, presence: true, numericality: { greater_than: 0 }
  validates :storage_key, presence: true
  validates :storage_path, presence: true
  validates :storage_provider, presence: true

  scope :by_provider, ->(provider) { where(storage_provider: provider) }

  def url
    case storage_provider.to_sym
    when :s3
      storage_path # Direct S3 URL or presigned if needed
    when :distributed
      "#{ENV['DISTRIBUTED_STORAGE_BASE_URL']}/#{storage_key}"
    else
      storage_path
    end
  end
end
