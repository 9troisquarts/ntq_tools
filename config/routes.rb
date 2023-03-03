NtqTools::Engine.routes.draw do
  resource :translation, only: [:update, :show]
  get '/translation/refresh' => "translations#refresh"

  if NtqTools.impersonation_enabled && NtqTools.impersonation_user_models.any? && defined?(Devise)
    get '/impersonation/users' => "impersonation#index"
    get "/impersonation/:model_name/:id/sign_in" => "impersonation#signin"
  end
end
