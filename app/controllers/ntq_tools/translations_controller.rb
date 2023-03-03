require 'ntq_tools/translations/translation_tool'
module NtqTools
  class TranslationsController < NtqTools::ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :check_presence_of_key, except: [:refresh]

    def show
      return  render json: { data: nil }, status: 404 unless I18n.exists?(params[:key].to_s)
      
      render json: {
        data: I18n.t(params[:key])
      }, status: 200
    end

    def update
      return render json: { status: "NOK", message: "value is missing" }, status: 400 unless params[:value].present?

      NtqTools::Translations::TranslationTool.modify(params[:key].to_s, { "#{I18n.locale}": params[:value] })

      render json: { data: true }, status: 200
    end 

    def refresh
      system("bundle exec rake react_on_rails:locale") if defined?(ReactOnRails)
    end

    private

      def check_presence_of_key
        return render json: { status: "NOK", message: "key params is missing" }, status: 400 unless params[:key].present?
      end
  end
end
