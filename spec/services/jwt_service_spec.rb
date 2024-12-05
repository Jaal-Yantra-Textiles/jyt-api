# spec/services/jwt_service_spec.rb
require 'rails_helper'

RSpec.describe JwtService do
  let(:payload) { { user_id: 1 } }
  let(:token) { described_class.encode(payload) }

  describe '.encode' do
    it 'returns a JWT token' do
      expect(token).to be_a(String)
      expect(token.split('.').size).to eq(3)
    end
  end

  describe '.decode' do
    it 'returns the original payload' do
      decoded_payload = described_class.decode(token)
      expect(decoded_payload['user_id']).to eq(payload[:user_id])
    end

    context 'with invalid token' do
      it 'returns nil' do
        expect(described_class.decode('invalid_token')).to be_nil
      end
    end
  end
end
