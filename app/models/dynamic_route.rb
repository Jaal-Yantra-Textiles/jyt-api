class DynamicRoute < ApplicationRecord
  validates :path, :controller, :action, :method, :organization_id, presence: true

  # Updated regex to allow URL parameters
  validates :path, format: {
    with: %r{\A/[a-zA-Z0-9/_\-]+(/:[\w]+)*\z},
    message: "must start with '/' and can only contain letters, numbers, underscores, hyphens, and valid URL parameters"
  }

  validates :method,
    inclusion: {
      in: %w[GET POST PUT PATCH DELETE],
      message: "must be a valid HTTP method"
    }
end
