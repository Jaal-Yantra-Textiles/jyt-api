require 'rails_helper'

RSpec.describe DynamicRoute, type: :model do
  describe "validations" do
    subject { build(:dynamic_route) }

    # Presence validations
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:controller) }
    it { should validate_presence_of(:action) }
    it { should validate_presence_of(:method) }
    it { should validate_presence_of(:organization_id) }

    # Method validation
    it { should validate_inclusion_of(:method)
           .in_array(%w[GET POST PUT PATCH DELETE])
           .with_message("must be a valid HTTP method") }

    # Path format validation
    it { should allow_value("/path").for(:path) }
    it { should allow_value("/path/to/resource").for(:path) }
    it { should allow_value("/path-with-hyphens").for(:path) }
    it { should allow_value("/path_with_underscores").for(:path) }
    it { should allow_value("/path123").for(:path) }

    it { should_not allow_value("path").for(:path)
           .with_message("must start with '/' and can only contain letters, numbers, underscores, hyphens, and valid URL parameters") }
    it { should_not allow_value("/path with spaces").for(:path)
           .with_message("must start with '/' and can only contain letters, numbers, underscores, hyphens, and valid URL parameters") }
    it { should_not allow_value("/path@special!chars").for(:path)
           .with_message("must start with '/' and can only contain letters, numbers, underscores, hyphens, and valid URL parameters") }
  end
end
