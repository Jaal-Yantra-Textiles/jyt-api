require 'rails_helper'

RSpec.describe Organization, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many(:invitations) }
    it { should have_and_belong_to_many(:members).class_name('User').join_table('organizations_users') }
  end

  # Validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:industry) }
  end

  describe 'instance methods' do
    let(:owner) { create(:user) }
    let(:organization) { create(:organization, owner: owner) }
    let(:user) { create(:user) }

    describe '#invite_user' do
      context 'with valid email' do
        it 'creates an invitation' do
          expect {
            organization.invite_user('test@example.com')
          }.to change(Invitation, :count).by(1)
        end

        it 'enqueues an invitation email' do
          expect {
            organization.invite_user('test@example.com')
          }.to have_enqueued_job.on_queue('default')
        end

        it 'sets the invitation status to pending' do
          organization.invite_user('test@example.com')
          expect(Invitation.last.status).to eq('pending')
        end

        it 'returns true on success' do
          expect(organization.invite_user('test@example.com')).to be true
        end
      end

      context 'with invalid invitation' do
        before do
          allow_any_instance_of(Invitation).to receive(:persisted?).and_return(false)
        end

        it 'returns false on failure' do
          expect(organization.invite_user('test@example.com')).to be false
        end

        it 'does not send an email' do
          expect {
            organization.invite_user('test@example.com')
          }.not_to have_enqueued_job.on_queue('mailers')
        end
      end
    end

    describe '#add_user' do
      context 'with new user' do
        it 'adds the user to the organization' do
          expect {
            organization.add_user(user)
          }.to change { organization.members.count }.by(1)  # Changed from users to members
        end

        it 'returns true on success' do
          expect(organization.add_user(user)).to be true
        end
      end

      context 'with already added user' do
        before { organization.members << user }  # Changed from users to members

        it 'does not add the user again' do
          expect {
            organization.add_user(user)
          }.not_to change { organization.members.count }  # Changed from users to members
        end

        it 'adds an error message' do
          organization.add_user(user)
          expect(organization.errors[:user]).to include("is already part of the organization")
        end

        it 'returns false' do
          expect(organization.add_user(user)).to be false
        end
      end
    end

    describe '#super_admin?' do
      it 'returns true for the owner' do
        expect(organization.super_admin?(owner)).to be true
      end

      it 'returns false for a regular user' do
        expect(organization.super_admin?(user)).to be false
      end

      it 'returns false for nil' do
        expect(organization.super_admin?(nil)).to be false
      end
    end
  end

  # Factory tests
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:organization)).to be_valid
    end

    it 'is invalid without a name' do
      expect(build(:organization, name: nil)).to be_invalid
    end

    it 'is invalid without an industry' do
      expect(build(:organization, industry: nil)).to be_invalid
    end

    it 'is invalid without an owner' do
      expect(build(:organization, owner: nil)).to be_invalid
    end
  end
end
