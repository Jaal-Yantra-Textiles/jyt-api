module Api
  module V1
    class HealthController < ApplicationController
      def index
        begin
          # This line checks if the DB is accessible by executing an actual query
          ActiveRecord::Base.connection.execute("SELECT 1")
          render json: { status: "OK", db_connected: true }
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid => e
          render json: { status: "ERROR", message: e.message, db_connected: false }, status: :service_unavailable
        end
      end
    end
  end
end
