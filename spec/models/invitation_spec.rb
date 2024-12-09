require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_inclusion_of(:status).in_array(%w[pending accepted rejected]) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      invitation = build(:invitation)
      expect(invitation).to be_valid
    end
  end

  describe 'default values' do
    it 'sets status to pending by default' do
      invitation = build(:invitation)
      expect(invitation.status).to eq('pending')
    end
  end
end
