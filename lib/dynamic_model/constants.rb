module DynamicModel
    module Constants
      SUPPORTED_FIELD_TYPES = %w[string text integer float decimal datetime boolean json].freeze
      SUPPORTED_RELATIONSHIP_TYPES = %w[belongs_to has_many has_one].freeze
      BASE_COLUMNS = %w[id organization_id created_at updated_at].freeze
    end
end
