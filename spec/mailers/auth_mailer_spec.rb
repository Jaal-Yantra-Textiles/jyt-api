require 'rails_helper'

RSpec.describe AuthMailer, type: :mailer do
  let(:user) { create(:user) }

  describe 'password_reset' do
    let(:mail) { described_class.with(user: user).password_reset }

    before do
      user.generate_password_reset!
    end

    it 'renders the headers' do
      expect(mail.subject).to eq('Reset your password')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@yourdomain.com'])
    end

    it 'includes reset token in body' do
      expect(mail.body.encoded).to include(user.reset_password_token)
    end
  end

  describe 'email_verification' do
    let(:mail) { described_class.with(user: user).email_verification }

    it 'renders the headers' do
      expect(mail.subject).to eq('Verify your email')
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['noreply@yourdomain.com'])
    end

    it 'includes verification token in body' do
      expect(mail.body.encoded).to include(user.email_verification_token)
    end
  end
end
