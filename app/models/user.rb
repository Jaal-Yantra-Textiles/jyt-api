# app/models/user.rb
class User < ApplicationRecord
  has_secure_password validations: false
  has_secure_token :reset_password_token
  has_secure_token :email_verification_token
  has_many :owned_organizations,
      class_name: "Organization",
      foreign_key: :owner_id,
      dependent: :destroy

  has_and_belongs_to_many :member_organizations,
      class_name: "Organization",
      join_table: "organizations_users"

  # Enums
  enum :role,  customer: 0, admin: 1

  # Validations
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  # Email verification
  validates :email_verified_at, presence: true, allow_nil: true

  # Auth providers
  has_many :social_accounts, dependent: :destroy

  # Scopes
  scope :with_oauth, -> { where.not(oauth_provider: nil) }
  scope :by_provider, ->(provider) { where(oauth_provider: provider) }

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def verified?
    email_verified_at.present?
  end

  def verify_email!
    update(email_verified_at: Time.current, email_verification_token: nil)
  end

  def generate_password_reset!
    regenerate_reset_password_token
    update(reset_password_sent_at: Time.current)
  end

  def password_reset_expired?
    reset_password_sent_at < 2.hours.ago
  end

  def oauth_connected?
      oauth_provider.present?
  end

  def oauth_expired?
    oauth_expires_at.present? && oauth_expires_at < Time.current
  end

  def update_oauth_credentials(provider, token, expires_at)
    update(
      oauth_provider: provider,
      oauth_token: token,
      oauth_expires_at: Time.at(expires_at)
    )
  end

  def all_organizations
     Organization.where(id: owned_organization_ids + member_organization_ids)
  end

  private

  def password_required?
    !oauth_connected? && (new_record? || password.present?)
  end
end
