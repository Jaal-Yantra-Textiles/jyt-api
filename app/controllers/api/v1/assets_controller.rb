module Api
  module V1
    class AssetsController < ApplicationController
      before_action :authenticate_request
      before_action :set_organization
      before_action :set_asset, only: [ :show, :destroy ]

      def index
        @assets = @organization.assets
                               .order(created_at: :desc)
                               .page(params[:page])
                               .per(params[:per_page] || 20)

        render json: {
          assets: ActiveModelSerializers::SerializableResource.new(@assets, each_serializer: AssetSerializer),
          meta: {
            total_count: @assets.total_count,
            total_pages: @assets.total_pages,
            current_page: @assets.current_page
          }
        }
      end

      def show
        render json: @asset
      end

      def create
        @asset = @organization.assets.new(asset_params)
        @asset.created_by = current_user

        if @asset.save
          render json: @asset, status: :created
        else
          render json: { errors: @asset.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        if @asset.destroy
          head :no_content
        else
          render json: { errors: @asset.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_organization
        @organization = current_user.all_organizations.find(params[:organization_id])
      end

      def set_asset
        @asset = @organization.assets.find(params[:id])
      end

      def asset_params
        params.require(:asset).permit(
          :name,
          :content_type,
          :byte_size,
          :storage_provider,
          :storage_key,
          :storage_path,
          metadata: {}
        )
      end
    end
  end
end
