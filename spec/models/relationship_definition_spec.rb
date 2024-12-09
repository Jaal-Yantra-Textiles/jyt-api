require 'rails_helper'
RSpec.describe RelationshipDefinition, type: :model do
    describe "#relationship_details" do
      it "returns correct details for belongs_to relationship" do
        relationship_definition = RelationshipDefinition.new(
          name: "author",
          relationship_type: "belongs_to",
          target_model: "User"
        )
        expect(relationship_definition.relationship_details).to eq(
          {
            name: "author",
            relationship_type: "belongs_to",
            target_model: "User"
          }
        )
      end

      it "returns correct details for has_many relationship" do
        relationship_definition = RelationshipDefinition.new(
          name: "posts",
          relationship_type: "has_many",
          target_model: "Post"
        )
        expect(relationship_definition.relationship_details).to eq(
          {
            name: "posts",
            relationship_type: "has_many",
            target_model: "Post"
          }
        )
      end

      it "raises an error when relationship_type is invalid" do
        relationship_definition = RelationshipDefinition.new(
          name: "unknown",
          relationship_type: "invalid_type",
          target_model: "Model"
        )
        expect(relationship_definition.valid?).to be false
        expect(relationship_definition.errors[:relationship_type]).to include("is not included in the list")
      end

      it "raises an error when target_model is missing" do
        relationship_definition = RelationshipDefinition.new(
          name: "author",
          relationship_type: "belongs_to",
          target_model: nil
        )
        expect(relationship_definition.valid?).to be false
        expect(relationship_definition.errors[:target_model]).to include("can't be blank")
      end
    end
  end
