module DynamicModel
    module Validations
      include Constants
      private

      def validate_model_definition!
        validate_basic_attributes!
        validate_fields!
        validate_relationships!
      end

      def setup_field_validations(klass)
        model_definition.field_definitions.each do |field|
          setup_single_field_validation(klass, field)
        end
      end

      def setup_single_field_validation(klass, field)
        options = field.options || {}
        validators = []

        # Common validations
        validators << presence_validator(field) if options["required"]
        validators << unique_validator(field) if options["unique"]

        # Type-specific validations
        type_validators = case field.field_type
        when "string"   then string_validators(field)
        when "text"     then text_validators(field)
        when "integer"  then integer_validators(field)
        when "decimal"  then decimal_validators(field)
        when "boolean"  then boolean_validators(field)
        when "date"     then date_validators(field)
        when "datetime" then datetime_validators(field)
        when "email"    then email_validators(field)
        when "url"      then url_validators(field)
        when "enum"     then enum_validators(field)
        when "json"     then json_validators(field)
        when "array"    then array_validators(field)
        end

        validators << type_validators if type_validators

        # Apply all collected validators to the field
        validators.compact.each do |validator|
          klass.validates(field.name.to_sym, validator)
        end
      end

      private
      def presence_validator(field)
        { presence: true }
      end

      def unique_validator(field)
        { uniqueness: true }
      end

      # String validators
      def string_validators(field)
        options = field.options || {}
        validators = {}

        validators[:length] = length_constraints(options)
        validators[:format] = { with: options["pattern"] } if options["pattern"]
        validators
      end

      # Text validators
      def text_validators(field)
        options = field.options || {}
        validators = {}

        validators[:length] = length_constraints(options)
        validators
      end

      # Integer validators
      def integer_validators(field)
        options = field.options || {}
        validators = { numericality: { only_integer: true } }

        add_number_constraints(validators[:numericality], options)
        validators
      end

      # Decimal validators
      def decimal_validators(field)
        options = field.options || {}
        validators = { numericality: true }

        add_number_constraints(validators[:numericality], options)
        validators[:numericality][:decimal] = true if options["precision"] || options["scale"]
        validators
      end

      # Boolean validators
      def boolean_validators(field)
        { inclusion: { in: [ true, false ] } }
      end

      # Date validators
      def date_validators(field)
        options = field.options || {}
        validators = {}

        if options["min_date"] || options["max_date"]
          validators[:inclusion] = date_range_constraints(options)
        end
        validators
      end

      # Datetime validators
      def datetime_validators(field)
        options = field.options || {}
        validators = {}

        if options["min_datetime"] || options["max_datetime"]
          validators[:inclusion] = datetime_range_constraints(options)
        end
        validators
      end

      # Email validators
      def email_validators(field)
        {
          format: {
            with: URI::MailTo::EMAIL_REGEXP,
            message: "must be a valid email address"
          }
        }
      end

      # URL validators
      def url_validators(field)
        {
          format: {
            with: URI.regexp(%w[http https]),
            message: "must be a valid URL"
          }
        }
      end

      # Enum validators
      def enum_validators(field)
        options = field.options || {}
        return unless options["values"].is_a?(Array)

        {
          inclusion: {
            in: options["values"],
            message: "must be one of: #{options['values'].join(', ')}"
          }
        }
      end

      # JSON validators
      def json_validators(field)
        options = field.options || {}

        {
          json: true,
          schema: options["schema"]
        }
      end

      # Array validators
      def array_validators(field)
        options = field.options || {}
        validators = { array: true }

        if options["min_items"] || options["max_items"]
          validators[:length] = length_constraints(options, "min_items", "max_items")
        end

        validators
      end

      # Helper methods for building constraints
      def length_constraints(options, min_key = "min_length", max_key = "max_length")
        constraints = {}
        constraints[:minimum] = options[min_key] if options[min_key]
        constraints[:maximum] = options[max_key] if options[max_key]
        constraints unless constraints.empty?
      end

      def add_number_constraints(validator_options, field_options)
        validator_options[:greater_than] = field_options["min"] if field_options["min"]
        validator_options[:less_than] = field_options["max"] if field_options["max"]
        validator_options[:equal_to] = field_options["equal_to"] if field_options["equal_to"]
        validator_options[:other_than] = field_options["other_than"] if field_options["other_than"]
        validator_options[:odd] = true if field_options["odd"]
        validator_options[:even] = true if field_options["even"]
      end

      def date_range_constraints(options)
        range = {}
        range[:min] = parse_date(options["min_date"]) if options["min_date"]
        range[:max] = parse_date(options["max_date"]) if options["max_date"]
        { in: (range[:min]..range[:max]) } unless range.empty?
      end

      def datetime_range_constraints(options)
        range = {}
        range[:min] = parse_datetime(options["min_datetime"]) if options["min_datetime"]
        range[:max] = parse_datetime(options["max_datetime"]) if options["max_datetime"]
        { in: (range[:min]..range[:max]) } unless range.empty?
      end

      def parse_date(date_string)
        Date.parse(date_string)
      rescue ArgumentError
        nil
      end

      def parse_datetime(datetime_string)
        DateTime.parse(datetime_string)
      rescue ArgumentError
        nil
      end

      def validate_basic_attributes!
        raise ValidationError, "Model name cannot be blank" if model_definition.name.blank?
        raise ValidationError, "Organization ID cannot be blank" if org_id.blank?
        raise ValidationError, "Invalid model name format" unless valid_identifier?(model_definition.name)
      end

      def validate_fields!
        model_definition.field_definitions.each do |field|
          unless SUPPORTED_FIELD_TYPES.include?(field.field_type)
            raise ValidationError, "Unsupported field type: #{field.field_type}"
          end
          raise ValidationError, "Field name cannot be blank" if field.name.blank?
          raise ValidationError, "Invalid field name format" unless valid_identifier?(field.name)
        end
      end

      def validate_relationships!
        model_definition.relationship_definitions.each do |rel|
          unless SUPPORTED_RELATIONSHIP_TYPES.include?(rel.relationship_type)
            raise ValidationError, "Unsupported relationship type: #{rel.relationship_type}"
          end
          raise ValidationError, "Relationship name cannot be blank" if rel.name.blank?
          raise ValidationError, "Target model cannot be blank" if rel.target_model.blank?
          raise ValidationError, "Invalid relationship name format" unless valid_identifier?(rel.name)
        end
      end

      def valid_identifier?(name)
        name.present? && name =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
      end
    end
end
