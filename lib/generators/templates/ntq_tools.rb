NtqTools.setup do |config|

  # Impersonation allow to sign in as user without password or Oauth
  ## impersonation_label can be defined on model for customizing the select label
  ## after_impersonation_path can be defined for specifying path redirection of resource
  config.impersonation_enabled = true
  config.impersonation_user_models = ["User"]

end