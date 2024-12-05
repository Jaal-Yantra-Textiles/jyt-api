class ModelDefinitionSerializer
  include JSONAPI::Serializer

  attributes :name, :created_at

  has_many :field_definitions
  has_many :relationship_definitions

  attribute :fields_attributes do |object|
    object.field_definitions.map do |field|
      {
        name: field.name,
        field_type: field.field_type,
        options: field.options
      }
    end
  end

  attribute :relationships_attributes do |object|
    object.relationship_definitions.map do |rel|
      {
        name: rel.name,
        relationship_type: rel.relationship_type,
        target_model: rel.target_model,
        options: rel.options
      }
    end
  end
end
