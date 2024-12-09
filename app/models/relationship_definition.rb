class RelationshipDefinition < ApplicationRecord
  belongs_to :dynamic_model_definition

  VALID_TYPES = %w[belongs_to has_many has_one has_and_belongs_to_many]

  validates :name, presence: true
  validates :relationship_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :target_model, presence: true

  def relationship_details
    {
      name: name,
      relationship_type: relationship_type,
      target_model: target_model
    }
  end
end
