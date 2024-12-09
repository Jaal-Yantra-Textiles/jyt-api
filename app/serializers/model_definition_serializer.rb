class ModelDefinitionSerializer
  include JSONAPI::Serializer

  attributes :name, :description, :created_at, :updated_at, :organization_id

  has_many :field_definitions
  has_many :relationship_definitions

  attribute :fields_attributes do |object|
    object.field_definitions.map do |field|
      {
        id: field.id,
        name: field.name,
        field_type: field.field_type,
        options: field.options
      }
    end
  end

  attribute :relationship_definitions_attributes do |object|
    object.relationship_definitions.map do |rel|
      {
        id: rel.id,
        name: rel.name,
        relationship_type: rel.relationship_type,
        target_model: rel.target_model,
        options: rel.options
      }
    end
  end
end
