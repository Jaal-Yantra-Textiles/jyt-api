
require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { should belong_to(:owner).class_name('User') }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:industry) }
end
