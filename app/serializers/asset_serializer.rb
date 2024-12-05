class AssetSerializer < ActiveModel::Serializer
  attributes :id, :name, :content_type, :byte_size,
             :storage_provider, :storage_path, :url,
             :created_at, :updated_at, :metadata

  belongs_to :created_by, serializer: UserSerializer

  def url
    object.url
  end
end
