# app/serializers/relationship_definition_serializer.rb
class RelationshipDefinitionSerializer
    include JSONAPI::Serializer

    attributes :name, :relationship_type, :target_model, :options
end
