class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :full_name,  :role,
             :email_verified_at, :created_at, :updated_at

  def email_verified_at
    object.email_verified_at&.iso8601
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end

  def full_name
    object.full_name
  end
end
