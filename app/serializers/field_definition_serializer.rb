# app/serializers/field_definition_serializer.rb
class FieldDefinitionSerializer
    include JSONAPI::Serializer

    attributes :name, :field_type, :options
end
