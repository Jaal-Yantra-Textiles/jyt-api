RSpec.shared_context 'dynamic model context' do
  let(:valid_field_attributes) do
    {
      name: 'title',
      field_type: 'string',
      options: {
        nullable: false,
        filterable: true,
        index: true,
        validations: {
          presence: true,
          length: { maximum: 100 }
        }
      }
    }
  end

  let(:valid_relationship_attributes) do
    {
      name: 'user',
      relationship_type: 'belongs_to',
      target_model: 'User',
      options: {
        foreign_key: 'user_id',
        optional: false
      }
    }
  end

  let(:valid_model_attributes) do
    {
      name: 'Project',
      fields_attributes: [ valid_field_attributes ],
      relationships_attributes: [ valid_relationship_attributes ]
    }
  end
end
