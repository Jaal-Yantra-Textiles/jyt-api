require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password)}

    it 'validates length of password to be at least 6 characters' do
      user = build(:user, password: 'short', password_confirmation: 'short')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end
    it 'validates email format' do
      user = build(:user, email: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(customer: 0, admin: 1) }
  end

  describe '#full_name' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    it 'returns the full name' do
      expect(user.full_name).to eq('John Doe')
    end
  end
  describe 'oauth methods' do
      describe '#oauth_connected?' do
        it 'returns true when oauth_provider is present' do
          user = build(:user, :with_oauth)
          expect(user.oauth_connected?).to be true
        end

        it 'returns false when oauth_provider is nil' do
          user = build(:user)
          expect(user.oauth_connected?).to be false
        end
      end

      describe '#oauth_expired?' do
        it 'returns true when oauth_expires_at is in the past' do
          user = build(:user, :with_oauth, oauth_expires_at: 1.hour.ago)
          expect(user.oauth_expired?).to be true
        end

        it 'returns false when oauth_expires_at is in the future' do
          user = build(:user, :with_oauth, oauth_expires_at: 1.hour.from_now)
          expect(user.oauth_expired?).to be false
        end
      end

      describe '#update_oauth_credentials' do
        let(:user) { create(:user) }
        let(:provider) { 'google_oauth2' }
        let(:token) { SecureRandom.hex(32) }
        let(:expires_at) { 1.hour.from_now.to_i }

        it 'updates oauth credentials' do
          user.update_oauth_credentials(provider, token, expires_at)

          expect(user.oauth_provider).to eq(provider)
          expect(user.oauth_token).to eq(token)
          expect(user.oauth_expires_at).to be_within(1.second).of(Time.at(expires_at))
        end
      end
    end

    describe 'password validation' do
      context 'with oauth user' do
        it 'does not require password' do
          user = build(:user, :with_oauth, password: nil, password_confirmation: nil)
          expect(user).to be_valid
        end
      end

      context 'without oauth' do
        it 'requires password' do
          user = build(:user, password: nil, password_confirmation: nil)
          expect(user).not_to be_valid
        end
      end
    end

    describe 'scopes' do
      before do
        create(:user, :with_oauth)
        create(:user, :with_facebook)
        create(:user)
      end

      describe '.with_oauth' do
        it 'returns only users with oauth providers' do
          expect(User.with_oauth.count).to eq(2)
        end
      end

      describe '.by_provider' do
        it 'returns users filtered by provider' do
          expect(User.by_provider('google_oauth2').count).to eq(1)
          expect(User.by_provider('facebook').count).to eq(1)
        end
      end
    end
end
