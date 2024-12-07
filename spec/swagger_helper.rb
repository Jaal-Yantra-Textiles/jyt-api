# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      components: {
        securitySchemes: {  # "Schemas" was misspelled as "Schemas"
          bearer_auth: {
            type: :http,    # "https" should be "http"
            scheme: :bearer,
            bearer_format: 'JWT'
          }
        }
      },
      servers: [
        {
          url: 'https://local.yourdomain.com:3000',  # Changed https to http for local development
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          description: 'Production server',
          variables: {
            defaultHost: {
              default: 'www.example.com'
            }
          }
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
