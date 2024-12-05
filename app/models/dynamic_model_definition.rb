class DynamicModelDefinition < ApplicationRecord
  has_many :field_definitions, dependent: :destroy
  has_many :relationship_definitions, dependent: :destroy

  accepts_nested_attributes_for :field_definitions, :relationship_definitions

  validates :name, presence: true,
                    format: { with: /\A[A-Za-z][A-Za-z0-9_]*\z/,
                             message: "must start with a letter and can only contain letters, numbers, and underscores" }

  after_create :generate_model_files

  private

  def generate_model_files
    DynamicModelService.new(self).generate
  end
end
