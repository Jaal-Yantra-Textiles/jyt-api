class DynamicModelDefinition < ApplicationRecord
  belongs_to :organization
  has_many :field_definitions, dependent: :destroy
  has_many :relationship_definitions, dependent: :destroy

  accepts_nested_attributes_for :field_definitions, allow_destroy: true
  accepts_nested_attributes_for :relationship_definitions, allow_destroy: true

  validates :name, presence: true,
                  format: { with: /\A[A-Z][A-Za-z0-9]*\z/,
                           message: "must start with an uppercase letter and can only contain letters and numbers" }
  validates :name, uniqueness: { scope: :organization_id }
  validates :organization, presence: true

  before_validation :strip_name

  def table_name
    "org_#{organization_id}_#{name.underscore.pluralize}"
  end

  def field_names
    field_definitions.pluck(:name)
  end

  def relationship_names
    relationship_definitions.pluck(:name)
  end

  private

  def strip_name
    self.name = name.strip if name.present?
  end
end
