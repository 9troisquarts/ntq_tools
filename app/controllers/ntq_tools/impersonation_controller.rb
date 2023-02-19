module NtqTools
  class ImpersonationController < NtqTools::ApplicationController
    
    before_action :check_impersonation_enabled, except: [:config]
    before_action :model_name_is_valid?, only: [:sign_in]

    def index
      data = {}
      NtqTools.impersonation_user_models.each do |model|
        data[model.underscore] = model.constantize.all.map{|user| {
          id: user.id,
          label: label_for_user(user),
        }}
      end
      render json: { data: data }
    end

    def signin
      @resource = params[:model_name].camelize.constantize.find params[:id]
      sign_in(@resource)
      return redirect_to @resource.after_impersonation_path if @resource.respond_to?(:after_impersonation_path)

      redirect_to after_sign_in_path_for(@resource)
    end

    private

    def label_for_user(user, config = nil)
      return user.impersonation_label if user.respond_to?(:impersonation_label)

      return user.full_name if user.respond_to?(:full_name)

      return user.email if user.respond_to?(:email)

      user.id
    end

    def model_name_is_valid?
      return render json: {}, status: 404 unless params[:model_name].present? && NtqTools.impersonation_user_models.include?(params[:model_name].camelize)
    end

    def check_impersonation_enabled
      return render json: {}, status: 404 unless NtqTools.impersonation_enabled && NtqTools.impersonation_user_models.present?
    end
  end
end