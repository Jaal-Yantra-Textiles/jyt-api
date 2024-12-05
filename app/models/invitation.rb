class Invitation < ApplicationRecord
  belongs_to :organization
  validates :email, presence: true
  validates :status, inclusion: { in: %w[pending accepted rejected] }
end
