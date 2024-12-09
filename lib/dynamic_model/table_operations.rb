module DynamicModel
  module TableOperations
    extend ActiveSupport::Concern

    private

    # Table Existence and Creation
    def ensure_table_exists
      Rails.logger.info "Ensuring table exists for #{model_definition.name}..."

      unless ActiveRecord::Base.connection.table_exists?(table_name)
        ActiveRecord::Base.connection.execute(table_creation_sql)
        Rails.logger.info "Table created for #{model_definition.name}."
      end
    rescue StandardError => e
      Rails.logger.error "Error creating table for #{model_definition.name}: #{e.message}"
      raise TableOperationError, "Failed to create table: #{e.message}"
    end

    def table_creation_sql
      columns = [ "id SERIAL PRIMARY KEY" ]

      field_sql = generate_field_definitions
      columns << field_sql if field_sql.present?

      relationship_sql = generate_relationship_columns
      columns << relationship_sql if relationship_sql.present?

      columns << "organization_id INTEGER NOT NULL REFERENCES organizations(id)"
      columns << "created_at TIMESTAMP"
      columns << "updated_at TIMESTAMP"

      <<-SQL.strip_heredoc
        CREATE TABLE #{table_name} (
          #{columns.join(",\n      ")}
        );
      SQL
    end

    def generate_field_definitions
      model_definition.field_definitions.map do |field|
        sql_type = sql_type_for_field(field)
        options = generate_column_options(field)

        column_definition = "#{field.name} #{sql_type}"
        column_definition += " DEFAULT #{options[:default]}" if options[:default].present?
        column_definition += " NOT NULL" unless options[:null]
        column_definition
      end.join(",\n")
    end

    def generate_relationship_columns
      model_definition.relationship_definitions
        .select { |rel| rel.relationship_type == "belongs_to" }
        .map do |rel|
          target_table = "org_#{org_id}_#{rel.target_model.underscore.pluralize}"
          "#{rel.name}_id INTEGER REFERENCES #{target_table}(id)"
        end.join(",\n")
    end

    # Table Updates
    def update_table_structure
      new_columns = generate_new_columns
      existing_columns = current_column_names

      ActiveRecord::Base.connection.transaction do
        # Add new columns
        new_columns.each do |column|
          unless existing_columns.include?(column[:name])
            add_column(column)
          end
        end

        # Remove old columns
        existing_columns.each do |column_name|
          next if system_column?(column_name)
          next if new_columns.any? { |c| c[:name] == column_name }
          remove_column(column_name)
        end
      end
    end

    def generate_new_columns
      model_definition.field_definitions.map do |field|
        {
          name: field.name,
          type: sql_type_for_field(field),
          options: generate_column_options(field)
        }
      end
    end

    # Column Type and Options
    def sql_type_for_field(field)
      case field.field_type
      when "string"   then "VARCHAR"
      when "text"     then "TEXT"
      when "integer"  then "INTEGER"
      when "float"    then "DOUBLE PRECISION"
      when "decimal"  then "NUMERIC(10, 2)"
      when "datetime" then "TIMESTAMP"
      when "boolean"  then "BOOLEAN"
      when "json"     then "JSONB"
      else
        raise DynamicModel::ValidationError, "Unsupported field type: #{field.field_type}"
      end
    end

    def generate_column_options(field)
      options = {}
      field_options = field.options || {}

      # Set defaults based on type
      if field.field_type == "boolean"
        options[:default] = "FALSE"
      elsif field.field_type == "json"
        options[:default] = "'{}'"
      end

      # Override with specified defaults if present
      options[:default] = quote_default_value(field_options["default"]) if field_options["default"].present?

      # Set null constraint
      options[:null] = !field_options["required"]

      options
    end

    def quote_default_value(value)
      return value if value.is_a?(Numeric)
      return value if [ "TRUE", "FALSE", "NULL" ].include?(value.to_s.upcase)
      "'#{value}'"
    end

    # Column Operations
    def add_column(column)
      sql = "ALTER TABLE #{table_name} ADD COLUMN #{column[:name]} #{column[:type]}"
      sql += " DEFAULT #{column[:options][:default]}" if column[:options][:default].present?
      sql += " NOT NULL" unless column[:options][:null]

      ActiveRecord::Base.connection.execute(sql)
    end

    def remove_column(column_name)
      ActiveRecord::Base.connection.execute(
        "ALTER TABLE #{table_name} DROP COLUMN #{column_name}"
      )
    end

    # Table Removal
    def remove_table_with_dependencies
      Rails.logger.info "Removing table and dependencies for #{model_definition.name}"

      ActiveRecord::Base.connection.transaction do
        remove_incoming_foreign_keys
        remove_join_tables
        drop_main_table
      end
    rescue StandardError => e
      Rails.logger.error "Failed to remove table #{model_definition.name}: #{e.message}"
      raise
    end

    def remove_incoming_foreign_keys
      connection = ActiveRecord::Base.connection

      tables = connection.tables.select do |table_name|
        next if table_name == table_name

        foreign_keys = connection.foreign_keys(table_name)
        foreign_keys.any? { |fk| fk.to_table == table_name }
      end

      tables.each do |t|
        foreign_keys = connection.foreign_keys(t)
        foreign_keys.each do |fk|
          if fk.to_table == table_name
            connection.remove_foreign_key t, name: fk.name
          end
        end
      end
    end

    def remove_join_tables
      habtm_relationships = model_definition.relationship_definitions.select do |rel|
        rel.relationship_type == :has_and_belongs_to_many
      end

      connection = ActiveRecord::Base.connection

      habtm_relationships.each do |rel|
        join_table_name = rel.join_table_name
        if connection.table_exists?(join_table_name)
          connection.drop_table(join_table_name)
          Rails.logger.info "Dropped join table: #{join_table_name}"
        end
      end
    end

    def drop_main_table
      connection = ActiveRecord::Base.connection
      if connection.table_exists?(table_name)
        connection.drop_table(table_name)
        Rails.logger.info "Dropped table: #{table_name}"
      end
    end

    # Helper Methods
    def current_column_names
      ActiveRecord::Base.connection.columns(table_name).map(&:name)
    end

    def system_column?(column_name)
      [ "id", "created_at", "updated_at", "organization_id" ].include?(column_name)
    end
  end
end
