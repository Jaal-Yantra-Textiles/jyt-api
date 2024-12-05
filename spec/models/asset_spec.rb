
require 'rails_helper'

RSpec.describe Asset, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, owner: user) }
  let(:asset) do
    create(:asset,
           name: 'Test Asset',
           content_type: 'application/pdf',
           byte_size: 1024,
           storage_provider: 's3',
           storage_key: 'test/test.pdf',
           storage_path: 'https://s3.amazonaws.com/bucket/test/test.pdf',
           organization: organization,
           created_by: user)
  end

  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:created_by).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:content_type) }
    it { should validate_presence_of(:byte_size) }
    it { should validate_numericality_of(:byte_size).is_greater_than(0) }
    it { should validate_presence_of(:storage_key) }
    it { should validate_presence_of(:storage_path) }
    it { should validate_presence_of(:storage_provider) }
  end

  describe 'enums' do
    it { should define_enum_for(:storage_provider).with_values(s3: 0, distributed: 1) }
  end

  describe 'scopes' do
    describe '.by_provider' do
      let!(:s3_asset) { create(:asset, storage_provider: 's3', organization: organization, created_by: user) }
      let!(:distributed_asset) { create(:asset, storage_provider: 'distributed', organization: organization, created_by: user) }

      it 'returns assets by specified provider' do
        expect(Asset.by_provider('s3')).to include(s3_asset)
        expect(Asset.by_provider('s3')).not_to include(distributed_asset)
      end
    end
  end

  describe '#url' do
    context 'when storage_provider is s3' do
      it 'returns the storage_path as the URL' do
        expect(asset.url).to eq('https://s3.amazonaws.com/bucket/test/test.pdf')
      end
    end

    context 'when storage_provider is distributed' do
      before do
        asset.update(storage_provider: 'distributed', storage_key: 'distributed/test.pdf')
        allow(ENV).to receive(:[]).with('DISTRIBUTED_STORAGE_BASE_URL').and_return('https://distributed.storage.com')
      end

      it 'returns the distributed storage URL' do
        expect(asset.url).to eq('https://distributed.storage.com/distributed/test.pdf')
      end
    end
  end
end
