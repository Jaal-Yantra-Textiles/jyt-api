class DynamicModelLoader
  class ModelLoadError < StandardError; end

  SUPPORTED_FIELD_TYPES = %w[
    string text integer float decimal
    boolean date datetime email url
    enum json array
  ].freeze

  SUPPORTED_RELATIONSHIP_TYPES = %w[
    belongs_to has_many has_one has_and_belongs_to_many
  ].freeze

  class << self
    def load_model(model_definition)
      class_name = generate_class_name(model_definition)
      validate_model_definition!(model_definition)
      validate_relationships!(model_definition)
      unload_model(class_name)

      klass = Class.new(ApplicationRecord)

      klass.class_eval do
        self.table_name = "org_#{model_definition.organization_id}_#{model_definition.name.underscore.pluralize}"
        validates :organization_id, presence: true
        belongs_to :organization
        default_scope { where(organization_id: model_definition.organization_id) }
      end

      # Set up field validations
      model_definition.field_definitions.each do |field|
        setup_field_validations(klass, field)
      end

      # Set up relationships
      puts "Setting up relationships for #{class_name}"
      model_definition.relationship_definitions.each do |rel|
        puts "Setting up relationship: #{rel.inspect}"
        setup_relationship(klass, rel, model_definition.organization_id)
      end

      # Log the configuration for debugging
      log_model_configuration(klass)

      Object.const_set(class_name, klass)
      klass
    rescue StandardError => e
      Rails.logger.error "Failed to load model #{class_name}: #{e.message}"
      raise ModelLoadError, "Failed to load model: #{e.message}"
    end

    def unload_model(class_name)
      if Object.const_defined?(class_name)
        Object.send(:remove_const, class_name)
        Rails.logger.info "Unloaded existing model: #{class_name}"
        true
      end
    rescue NameError => e
      Rails.logger.error "Error unloading model #{class_name}: #{e.message}"
      false
    end

    private

    def generate_class_name(model_definition)
      "Org#{model_definition.organization_id}#{model_definition.name.camelize}"
    end

    def validate_model_definition!(model_definition)
      raise ModelLoadError, "Model definition cannot be nil" if model_definition.nil?
      raise ModelLoadError, "Model name cannot be blank" if model_definition.name.blank?
      raise ModelLoadError, "Organization ID cannot be blank" if model_definition.organization_id.blank?
      raise ModelLoadError, "Field definitions cannot be nil" if model_definition.field_definitions.nil?

      validate_field_definitions!(model_definition.field_definitions)
    end

    def validate_field_definitions!(field_definitions)
      return if field_definitions.empty?

      field_definitions.each do |field|
        unless SUPPORTED_FIELD_TYPES.include?(field.field_type.to_s.downcase)
          raise ModelLoadError, "Unsupported field type: #{field.field_type}"
        end

        raise ModelLoadError, "Field name cannot be blank" if field.name.blank?
        raise ModelLoadError, "Invalid field name format" unless valid_identifier?(field.name)
      end
    end

    def validate_relationships!(model_definition)
      return unless model_definition.respond_to?(:relationship_definitions) &&
                    model_definition.relationship_definitions.present?

      model_definition.relationship_definitions.each do |rel|
        validate_single_relationship!(rel, model_definition.organization_id)
      end
    end

    def validate_single_relationship!(rel, organization_id)
      unless SUPPORTED_RELATIONSHIP_TYPES.include?(rel.relationship_type.to_s.downcase)
        raise ModelLoadError, "Invalid relationship type: #{rel.relationship_type}"
      end

      raise ModelLoadError, "Relationship name cannot be blank" if rel.name.blank?
      raise ModelLoadError, "Target model cannot be blank" if rel.target_model.blank?
      raise ModelLoadError, "Invalid relationship name format" unless valid_identifier?(rel.name)

      target_class_name = "Org#{organization_id}#{rel.target_model.classify}"
      unless model_exists?(target_class_name)
        raise ModelLoadError, "Invalid relationship: Target model '#{rel.target_model}' does not exist"
      end
    end

    def setup_field_validations(klass, field)
      return unless field && field.name.present?

      validations = build_field_validations(field)

      if validations.any?
        begin
          klass.validates field.name.to_sym, validations
        rescue ArgumentError => e
          Rails.logger.error "Failed to set up validations for field #{field.name}: #{e.message}"
          raise ModelLoadError, "Invalid validation configuration for field #{field.name}: #{e.message}"
        end
      end
    end

    def build_field_validations(field)
      options = field.options || {}
      validations = {}

      # Add presence validation if required
      validations[:presence] = true if options["required"] == true

      # Add type-specific validations
      case field.field_type.to_s.downcase
      when "string", "text"
        add_string_validations(validations, options)
      when "integer", "float", "decimal"
        add_numeric_validations(validations, options)
      when "boolean"
        add_boolean_validations(validations, options)
      when "date", "datetime"
        add_date_validations(validations, options)
      when "email"
        add_email_validations(validations, options)
      when "url"
        add_url_validations(validations, options)
      when "enum"
        add_enum_validations(validations, options)
      when "json"
        add_json_validations(validations, options)
      when "array"
        add_array_validations(validations, options)
      end

      validations
    end

    def setup_relationship(klass, rel, organization_id)
      return unless rel && rel.name.present?

      relationship_type = rel.relationship_type.to_s.downcase.to_sym
      target_class_name = "Org#{organization_id}#{rel.target_model.classify}"

      Rails.logger.info "Adding #{relationship_type} :#{rel.name} (class_name: #{target_class_name})"

      begin
        case relationship_type
        when :belongs_to
          klass.belongs_to rel.name.to_sym,
            class_name: target_class_name,
            optional: true
        when :has_many
          klass.has_many rel.name.to_sym,
            class_name: target_class_name,
            foreign_key: "#{klass.name.demodulize.underscore}_id",
            dependent: :destroy
        when :has_one
          klass.has_one rel.name.to_sym,
            class_name: target_class_name,
            foreign_key: "#{klass.name.demodulize.underscore}_id",
            dependent: :destroy
        when :has_and_belongs_to_many
          klass.has_and_belongs_to_many rel.name.to_sym,
            class_name: target_class_name,
            join_table: generate_join_table_name(klass.table_name, rel.target_model.pluralize)
        end
      rescue ArgumentError => e
        Rails.logger.error "Failed to set up relationship #{rel.name}: #{e.message}"
        raise ModelLoadError, "Invalid relationship configuration for #{rel.name}: #{e.message}"
      end
    end

    def add_string_validations(validations, options)
      if options["max_length"].present? || options["min_length"].present?
        length_options = {}
        length_options[:maximum] = options["max_length"].to_i if options["max_length"].present?
        length_options[:minimum] = options["min_length"].to_i if options["min_length"].present?
        validations[:length] = length_options
      end

      if options["format"].present?
        begin
          validations[:format] = {
            with: Regexp.new(options["format"]),
            allow_nil: !options["required"]
          }
        rescue RegexpError => e
          Rails.logger.error "Invalid regex pattern: #{e.message}"
        end
      end
    end

    def add_numeric_validations(validations, options)
      numeric_options = { allow_nil: !options["required"] }

      numeric_options[:greater_than_or_equal_to] = options["min"].to_f if options["min"].present?
      numeric_options[:less_than_or_equal_to] = options["max"].to_f if options["max"].present?
      numeric_options[:only_integer] = true if options["only_integer"]

      validations[:numericality] = numeric_options
    end

    def add_boolean_validations(validations, options)
      validations[:inclusion] = {
        in: [ true, false ],
        allow_nil: !options["required"]
      }
    end

    def add_date_validations(validations, options)
      if options["min_date"].present? || options["max_date"].present?
        date_range = parse_date_range(options["min_date"], options["max_date"])
        if date_range
          validations[:inclusion] = {
            in: date_range,
            allow_nil: !options["required"]
          }
        end
      end
    end

    def add_email_validations(validations, options)
      validations[:format] = {
        with: URI::MailTo::EMAIL_REGEXP,
        message: "must be a valid email address",
        allow_nil: !options["required"]
      }
    end

    def add_url_validations(validations, options)
      validations[:format] = {
        with: URI.regexp(%w[http https]),
        message: "must be a valid URL",
        allow_nil: !options["required"]
      }
    end

    def add_enum_validations(validations, options)
      if options["values"].is_a?(Array) && options["values"].any?
        validations[:inclusion] = {
          in: options["values"],
          allow_nil: !options["required"]
        }
      end
    end

    def add_json_validations(validations, options)
      if options["validate_json"]
        validations[:json] = true
        # Add custom validator if needed
        # klass.validates_with JsonValidator, attributes: [field.name.to_sym]
      end
    end

    def add_array_validations(validations, options)
      if options["min_items"].present? || options["max_items"].present?
        length_options = {}
        length_options[:minimum] = options["min_items"].to_i if options["min_items"].present?
        length_options[:maximum] = options["max_items"].to_i if options["max_items"].present?
        validations[:length] = length_options
      end
    end

    def model_exists?(class_name)
      Object.const_defined?(class_name) &&
        Object.const_get(class_name) < ApplicationRecord
    rescue NameError
      false
    end

    def valid_identifier?(name)
      name.present? && name =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
    end

    def generate_join_table_name(table1, table2)
      [ table1, table2 ].sort.join("_")
    end

    def parse_date_range(min_date, max_date)
      start_date = min_date ? Date.parse(min_date.to_s) : Date.new(1900)
      end_date = max_date ? Date.parse(max_date.to_s) : Date.new(2100)
      start_date..end_date
    rescue ArgumentError => e
      Rails.logger.error "Invalid date format: #{e.message}"
      nil
    end

    def log_model_configuration(klass)
      Rails.logger.debug "Model Configuration for #{klass.name}:"
      Rails.logger.debug "  Table: #{klass.table_name}"
      Rails.logger.debug "  Validations:"
      klass.validators.each do |validator|
        Rails.logger.debug "    #{validator.class.name} on #{validator.attributes.inspect}"
        Rails.logger.debug "    Options: #{validator.options.inspect}"
      end
    end
  end
end
