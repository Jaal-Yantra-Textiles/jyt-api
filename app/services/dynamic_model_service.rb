class DynamicModelService
  def initialize(model_definition)
    @model_definition = model_definition
    @org_id = model_definition.organization_id
  end

  def generate
    generate_migration
    generate_model
    generate_controller
    generate_routes
    reload_routes
  end

  def cleanup
    remove_model_files
    reload_routes
  end

  private

  def generate_migration
    Rails.logger.info "Generating migration for #{@model_definition.name}..."
    run_migration_dynamically(migration_content)
    Rails.logger.info "Migration executed successfully for #{@model_definition.name}."
  rescue StandardError => e
    Rails.logger.error "Failed to execute migration for #{@model_definition.name}: #{e.message}"
    raise "Migration failed. Changes have been rolled back."
  end

  def migration_content
    <<-RUBY
      create_table :org_#{@org_id}_#{@model_definition.name.underscore.pluralize} do |t|
        #{generate_fields}
        #{generate_relationship_columns}
        t.references :organization, null: false, foreign_key: true
        t.timestamps
      end

      #{generate_indexes}
      #{generate_join_tables}
    RUBY
  end

  def run_migration_dynamically(content)
    Rails.logger.info "Running migration dynamically..."

    migration_class = Class.new(ActiveRecord::Migration[7.0]) do
      define_method(:change) do
        eval(content)
      end
    end

    ActiveRecord::Base.transaction do
      migration_class.new.migrate(:up)
    rescue StandardError => e
      Rails.logger.error "Error in dynamic migration: #{e.message}"
      raise ActiveRecord::Rollback, "Rolling back migration due to error."
    end
  end

  def generate_fields
    @model_definition.field_definitions.map do |field|
      case field.field_type
      when "string", "text"
        "t.#{field.field_type} :#{field.name}"
      when "integer"
        "t.integer :#{field.name}"
      when "float"
        "t.float :#{field.name}"
      when "decimal"
        "t.decimal :#{field.name}, precision: 10, scale: 2"
      when "datetime"
        "t.datetime :#{field.name}"
      when "boolean"
        "t.boolean :#{field.name}, default: false"
      when "json"
        "t.jsonb :#{field.name}, default: {}"
      end
    end.join("\n      ")
  end

  def generate_relationship_columns
    @model_definition.relationship_definitions.map do |rel|
      unless rel.name && rel.relationship_type
        Rails.logger.error "Invalid relationship definition: #{rel.inspect}"
        next
      end

      case rel.relationship_type
      when "belongs_to"
        if rel.target_model.nil?
          Rails.logger.error "Missing target_model for belongs_to relationship: #{rel.inspect}"
          next
        end
        "t.references :#{rel.name}, null: #{rel.options.fetch('nullable', true)}, foreign_key: { to_table: :#{rel.target_model.tableize} }"
      when "has_one", "has_many"
        nil
      when "has_and_belongs_to_many"
        if rel.target_model.nil?
          Rails.logger.error "Missing target_model for HABTM relationship: #{rel.inspect}"
          next
        end
        create_join_table(rel)
      end
    end.compact.join("\n      ")
  end

  def create_join_table(rel)
    <<-RUBY
      create_table :org_#{@org_id}_#{@model_definition.name.underscore}_#{rel.name.pluralize} do |t|
        t.references :#{@model_definition.name.underscore}, null: false, foreign_key: { to_table: :org_#{@org_id}_#{@model_definition.name.underscore.pluralize} }
        t.references :#{rel.name.singularize}, null: false, foreign_key: { to_table: :#{rel.target_model.tableize} }
        t.timestamps
      end
      add_index :org_#{@org_id}_#{@model_definition.name.underscore}_#{rel.name.pluralize},
                [:#{@model_definition.name.underscore}_id, :#{rel.name.singularize}_id],
                unique: true,
                name: 'index_org_#{@org_id}_#{@model_definition.name.underscore}_#{rel.name}_unique'
    RUBY
  end

  def generate_indexes
    foreign_key_indexes = @model_definition.relationship_definitions
      .select { |rel| rel.relationship_type == "belongs_to" }
      .map { |rel| rel.name }

    indexes = @model_definition.field_definitions
      .select { |field| field.options["index"] }
      .reject { |field| foreign_key_indexes.include?(field.name) }
      .map { |field| "add_index :org_#{@org_id}_#{@model_definition.name.underscore.pluralize}, :#{field.name}" }

    relationship_indexes = @model_definition.relationship_definitions
      .select { |rel| rel.relationship_type == "belongs_to" }
      .reject { |rel| foreign_key_indexes.include?(rel.name) }
      .map { |rel| "add_index :org_#{@org_id}_#{@model_definition.name.underscore.pluralize}, :#{rel.name}_id" }

    (indexes + relationship_indexes).join("\n      ")
  end

  def generate_join_tables
    @model_definition.relationship_definitions
      .select { |rel| rel.relationship_type == "has_and_belongs_to_many" }
      .map do |rel|
        <<-RUBY
          create_table :org_#{@org_id}_#{@model_definition.name.underscore}_#{rel.name} do |t|
            t.references :#{@model_definition.name.underscore}
            t.references :#{rel.name.singularize}
            t.timestamps
          end
          add_index :org_#{@org_id}_#{@model_definition.name.underscore}_#{rel.name},
                    [:#{@model_definition.name.underscore}_id, :#{rel.name.singularize}_id],
                    unique: true,
                    name: 'index_org_#{@org_id}_#{@model_definition.name.underscore}_#{rel.name}_unique'
        RUBY
      end.join("\n")
  end

  def generate_model
    content = model_content
    File.write(model_path, content)
    load model_path
  end

  def model_path
    Rails.root.join("app/models/org_#{@org_id}_#{@model_definition.name.underscore}.rb")
  end

  def model_content
    <<-RUBY
      class Org#{@org_id}#{@model_definition.name.camelize} < ApplicationRecord
        belongs_to :organization
        #{generate_relationships}
        #{generate_validations}

        scope :for_organization, ->(org_id) { where(organization_id: org_id) }

        #{extend_related_models}
      end
    RUBY
  end

  def extend_related_models
    @model_definition.relationship_definitions.map do |rel|
      case rel.relationship_type
      when "has_many"
        <<-RUBY
          unless #{rel.target_model}.method_defined?(:#{rel.name.pluralize})
            #{rel.target_model}.class_eval do
              has_many :#{rel.name.pluralize}, class_name: 'Org#{@org_id}#{@model_definition.name.camelize}'
            end
          end
        RUBY
      when "belongs_to"
        <<-RUBY
          unless #{rel.target_model}.method_defined?(:#{rel.name})
            #{rel.target_model}.class_eval do
              belongs_to :#{rel.name}, class_name: 'Org#{@org_id}#{@model_definition.name.camelize}', optional: true
            end
          end
        RUBY
      end
    end.join("\n")
  end

  def generate_relationships
    @model_definition.relationship_definitions.map do |rel|
      case rel.relationship_type
      when "belongs_to"
        "belongs_to :#{rel.name}"
      when "has_many"
        "has_many :#{rel.name}, dependent: :destroy"
      when "has_one"
        "has_one :#{rel.name}, dependent: :destroy"
      when "has_and_belongs_to_many"
        "has_and_belongs_to_many :#{rel.name}"
      end
    end.join("\n    ")
  end

  def generate_validations
    @model_definition.field_definitions.map do |field|
      validations = []

      if field.options["validations"]
        field.options["validations"].each do |key, value|
          case key
          when "length"
            normalized_value = normalize_length_constraints(value)
            if valid_length_constraints?(normalized_value)
              validations << "validates :#{field.name}, length: #{normalized_value.symbolize_keys}"
            else
              Rails.logger.error "Invalid length constraints for #{field.name}: #{value.inspect}"
            end
          else
            validations << "validates :#{field.name}, #{key}: #{value.inspect}"
          end
        end
      end

      validations.join("\n    ")
    end.join("\n    ")
  end

  def normalize_length_constraints(constraints)
    return constraints unless constraints.is_a?(Hash)
    constraints.transform_values { |v| v.is_a?(String) && v.match?(/^\d+$/) ? v.to_i : v }
  end

  def valid_length_constraints?(constraints)
    return false unless constraints.is_a?(Hash)
    constraints.all? do |key, value|
      %w[maximum minimum is within].include?(key.to_s) && value.is_a?(Integer) && value >= 0
    end
  end


  def serialize_record(record)
    {
      data: {
        id: record.id,
        type: @model_definition.name.underscore,
        attributes: record.attributes.except("id", "created_at", "updated_at")
      }
    }
  end

  def generate_controller
    includes = generate_includes
    content = <<-RUBY
      module Api
        module V1
          class Org#{@org_id}#{@model_definition.name.camelize.pluralize}Controller < ApplicationController
            before_action :authenticate_user!
            before_action :ensure_organization_access

            def index
              @records = Org#{@org_id}#{@model_definition.name.camelize}
                .for_organization(current_organization.id)
                .includes(#{includes})
                render json: {
                    data: @records.map { |record| serialize_record(record)[:data] }
                  }
            end

            def show
              @record = Org#{@org_id}#{@model_definition.name.camelize}
                .for_organization(current_organization.id)
                .find(params[:id])
              render json: serialize_record(@record)
            end

            def create
              @record = Org#{@org_id}#{@model_definition.name.camelize}.new(record_params)
              @record.organization = current_organization

              if @record.save
                render json: serialize_record(@record), status: :created
              else
                render json: { errors: @record.errors.full_messages }, status: :unprocessable_entity
              end
            end

            def update
              @record = Org#{@org_id}#{@model_definition.name.camelize}
                .for_organization(current_organization.id)
                .find(params[:id])

              if @record.update(record_params)
                render json: serialize_record(@record)
              else
                render json: { errors: @record.errors.full_messages }, status: :unprocessable_entity
              end
            end

            def destroy
              @record = Org#{@org_id}#{@model_definition.name.camelize}
                .for_organization(current_organization.id)
                .find(params[:id])
              @record.destroy
              head :no_content
            end

            private

            def record_params
              params.require(:#{@model_definition.name.underscore}).permit(#{permitted_params})
            end
          end
        end
      end
    RUBY

    File.write(controller_path, content)
    load controller_path
  end

  def controller_path
    Rails.root.join("app/controllers/api/v1/org_#{@org_id}_#{@model_definition.name.underscore.pluralize}_controller.rb")
  end

  def permitted_params
    fields = @model_definition.field_definitions.map { |field| ":#{field.name}" }
    relationships = @model_definition.relationship_definitions
      .select { |rel| rel.relationship_type == "belongs_to" }
      .map { |rel| ":#{rel.name}_id" }
    (fields + relationships).join(", ")
  end

  def generate_includes
    @model_definition.relationship_definitions
      .select { |rel| %w[belongs_to has_one].include?(rel.relationship_type) }
      .map { |rel| ":#{rel.name}" }
      .to_s
  end

  def generate_routes
    content = <<-RUBY
      namespace :api do
        namespace :v1 do
          resources :org_#{@org_id}_#{@model_definition.name.underscore.pluralize}
        end
      end
    RUBY

    inject_routes(content)
  end

  def inject_routes(content)
    routes_file = Rails.root.join("config/routes.rb")
    routes_content = File.read(routes_file)

    return if routes_content.include?(content)

    inject_point = "Rails.application.routes.draw do\n"
    new_content = routes_content.sub(inject_point, "#{inject_point}  #{content}\n")

    File.write(routes_file, new_content)
  end

  def reload_routes
    Rails.application.reload_routes!
  rescue StandardError => e
    Rails.logger.error "Error reloading routes: #{e.message}"
    raise "Please reload routes manually."
  end

  def remove_model_files
    File.delete(model_path) if File.exist?(model_path)
    File.delete(controller_path) if File.exist?(controller_path)
  end
end
