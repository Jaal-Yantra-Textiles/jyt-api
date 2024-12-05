require 'rails_helper'

RSpec.describe SocialAccount, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }

    describe 'uniqueness' do
      subject { create(:social_account) }
      it { should validate_uniqueness_of(:uid).scoped_to(:provider) }
    end
  end
end
