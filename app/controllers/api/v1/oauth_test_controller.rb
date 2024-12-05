module Api
  module V1
    class OauthTestController < ApplicationController
      skip_before_action :authenticate_request

      def index
        render :index
      end
    end
  end
end
