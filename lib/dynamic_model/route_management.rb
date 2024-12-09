module DynamicModel
    module RouteManagement
      include Constants

      private

      def store_routes_in_db
        Rails.logger.info "Storing routes for #{model_definition.name}..."

        resource_path = build_resource_path
        Rails.logger.debug "Base resource path: #{resource_path}"

        validate_base_path!(resource_path)

        routes_to_create = [
          # Index and Create routes (collection)
          {
            path: resource_path,
            controller: controller_path,
            action: "index",
            method: "GET"
          },
          {
            path: resource_path,
            controller: controller_path,
            action: "create",
            method: "POST"
          },

          # Member routes (with :id)
          {
            path: "#{resource_path}/:id",
            controller: controller_path,
            action: "show",
            method: "GET"
          },
          {
            path: "#{resource_path}/:id",
            controller: controller_path,
            action: "update",
            method: "PUT"
          },
          {
            path: "#{resource_path}/:id",
            controller: controller_path,
            action: "update",
            method: "PATCH"
          },
          {
            path: "#{resource_path}/:id",
            controller: controller_path,
            action: "destroy",
            method: "DELETE"
          }
        ]

        Rails.logger.debug "Routes to create: #{routes_to_create.inspect}"

        begin
          ActiveRecord::Base.transaction do
            routes_to_create.each do |route_config|
              create_or_update_route(route_config)
            end
          end
        rescue StandardError => e
          Rails.logger.error "Error in route creation: #{e.message}"
          raise RouteError, e.message
        end
      end

      def validate_base_path!(path)
        unless path.start_with?("/")
          raise RouteError, "Path must start with '/'"
        end

        unless path =~ %r{\A/[a-zA-Z0-9/_\-]+\z}
          raise RouteError, "Invalid path format: #{path}"
        end
      end

      def create_or_update_route(route_config)
        Rails.logger.debug "Creating/updating route: #{route_config.inspect}"

        path = route_config[:path].to_s
        validate_route_path!(path)

        route = DynamicRoute.find_or_initialize_by(
          path: path,
          method: route_config[:method],
          organization_id: org_id
        )

        route.assign_attributes(
          controller: route_config[:controller],
          action: route_config[:action]
        )

        unless route.save
          error_msg = route.errors.full_messages.join(", ")
          Rails.logger.error "Route validation failed: #{error_msg}"
          raise RouteError, "Invalid route configuration: #{error_msg}"
        end

        Rails.logger.info "Successfully stored route: #{route.method} #{route.path}"
      end

      def validate_route_path!(path)
        Rails.logger.debug "Validating path: #{path}"

        unless path.is_a?(String)
          raise RouteError, "Path must be a string, got: #{path.class}"
        end

        unless path.start_with?("/")
          raise RouteError, "Path must start with '/', got: #{path}"
        end

        # Updated regex to properly handle URL parameters
        unless path =~ %r{\A/[a-zA-Z0-9/_\-]+(/:[\w]+)*\z}
          raise RouteError, "Invalid path format: #{path}"
        end

        Rails.logger.debug "Path validation successful for: #{path}"
      end

      def build_resource_path
        # Ensure all components are properly formatted
        safe_org_id = org_id.to_s.gsub(/[^0-9]/, "")
        safe_name = model_definition.name.underscore.pluralize.gsub(/[^a-z0-9_]/, "_")

        # Always start with a forward slash
        path = "/api/v1/org_#{safe_org_id}_#{safe_name}"

        Rails.logger.debug "Built resource path: #{path}"
        path
      end

      def controller_path
        "api/v1/org_#{org_id}_#{model_definition.name.underscore.pluralize}"
      end

      def delete_routes_from_db
        base_path = build_resource_path

        DynamicRoute.transaction do
          # Updated to handle both exact paths and paths with parameters
          DynamicRoute.where("path LIKE ? OR path LIKE ?",
            base_path, "#{base_path}/%")
            .where(organization_id: org_id)
            .destroy_all
        end

        Rails.logger.info "Deleted routes for #{model_definition.name}"
      rescue StandardError => e
        Rails.logger.error "Error deleting routes: #{e.message}"
        raise RouteError, "Failed to delete routes: #{e.message}"
      end

      def reload_routes
        Rails.logger.info "Reloading routes..."
        Rails.application.reload_routes!
      rescue StandardError => e
        raise RouteError, "Failed to reload routes: #{e.message}"
      end
    end
end
