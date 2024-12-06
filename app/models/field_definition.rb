class FieldDefinition < ApplicationRecord
  belongs_to :dynamic_model_definition

  VALID_TYPES = %w[string text integer float decimal datetime boolean json]

  validates :name, presence: true,
                  format: { with: /\A[a-z][a-z0-9_]*\z/,
                           message: "must start with a lowercase letter and can only contain lowercase letters, numbers, and underscores" }
  validates :field_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :options, presence: true
end
