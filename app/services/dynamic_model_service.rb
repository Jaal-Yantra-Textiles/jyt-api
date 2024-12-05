class DynamicModelService
  def initialize(model_definition)
    @model_definition = model_definition
  end

  def generate
    generate_migration
    generate_model
    create_api_controller
    update_routes
    Rails.application.reload_routes!
  end

  private

  def generate_migration
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    migration_content = migration_template

    File.write(
      Rails.root.join("db/migrate/#{timestamp}_create_#{@model_definition.name.tableize}.rb"),
      migration_content
    )

    Rails.application.load_tasks
    Rake::Task["db:migrate"].invoke
  end

  def migration_template
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    <<-MIGRATION
class Create#{@model_definition.name.classify.pluralize}#{timestamp} < ActiveRecord::Migration[8.0]
  def change
    create_table :#{@model_definition.name.tableize} do |t|
      #{generate_field_definitions}
      #{generate_relationship_columns}
      t.timestamps
    end

    #{generate_indexes}
  end
end
    MIGRATION
  end

  def generate_model
    model_content = model_template

    File.write(
      Rails.root.join("app/models/#{@model_definition.name.underscore}.rb"),
      model_content
    )

    # Reload model to make it available
    load "app/models/#{@model_definition.name.underscore}.rb"
  end

  def model_template
    <<-MODEL
class #{@model_definition.name.classify} < ApplicationRecord
  include Filterable
  include Sortable

  #{generate_relationships}
  #{generate_validations}

  def self.filterable_fields
    #{@model_definition.field_definitions.select { |f| f.options["filterable"] }.map(&:name)}
  end
end
    MODEL
  end

  def generate_relationships
      @model_definition.relationship_definitions.map do |relationship|
        case relationship.relationship_type
        when "belongs_to"
          "belongs_to :#{relationship.name.underscore}"
        when "has_many"
          "has_many :#{relationship.name.underscore.pluralize}"
        when "has_one"
          "has_one :#{relationship.name.underscore}"
        when "has_and_belongs_to_many"
          "has_and_belongs_to_many :#{relationship.name.underscore.pluralize}"
        end
      end.join("\n  ")
    end


    def generate_validations
        validations = []

        @model_definition.field_definitions.each do |field|
          field_validations = []

          if field.options&.dig("required")
            field_validations << "presence: true"
          end

          if field.options&.dig("unique")
            field_validations << "uniqueness: true"
          end

          if field.options&.dig("min")
            field_validations << "minimum: #{field.options['min']}"
          end

          if field.options&.dig("max")
            field_validations << "maximum: #{field.options['max']}"
          end

          if field.options&.dig("format")
            field_validations << "format: { with: /#{field.options['format']}/ }"
          end

          if field_validations.any?
            validations << "validates :#{field.name}, #{field_validations.join(', ')}"
          end
        end

        validations.join("\n  ")
      end

  def create_api_controller
    controller_content = controller_template

    FileUtils.mkdir_p(Rails.root.join("app/controllers/api"))
    File.write(
      Rails.root.join("app/controllers/api/#{@model_definition.name.tableize}_controller.rb"),
      controller_content
    )
  end

  def generate_field_definitions
      @model_definition.field_definitions.map do |field|
        case field.field_type
        when "string", "text"
          "t.#{field.field_type} :#{field.name}"
        when "integer"
          "t.integer :#{field.name}"
        when "float"
          "t.float :#{field.name}"
        when "decimal"
          "t.decimal :#{field.name}"
        when "datetime"
          "t.datetime :#{field.name}"
        when "boolean"
          "t.boolean :#{field.name}"
        when "json"
          "t.json :#{field.name}"
        end
      end.join("\n      ")
    end

    def generate_relationship_columns
        @model_definition.relationship_definitions.map do |relationship|
          if relationship.relationship_type == "belongs_to"
            "t.references :#{relationship.name.underscore}, foreign_key: { to_table: :#{relationship.target_model.tableize} }"
          end
        end.compact.join("\n      ")
      end

      def generate_indexes
          indexes = []

          @model_definition.field_definitions.each do |field|
            if field.options&.dig("index")
              indexes << "add_index :#{@model_definition.name.tableize}, :#{field.name}"
            end
          end

          @model_definition.relationship_definitions.each do |relationship|
            if relationship.relationship_type == "belongs_to"
              indexes << "add_index :#{@model_definition.name.tableize}, :#{relationship.name.underscore}_id"
            end
          end

          indexes.join("\n    ")
        end
end
