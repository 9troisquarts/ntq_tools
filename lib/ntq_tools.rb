require "ntq_tools/version"
require "ntq_tools/engine"

module NtqTools

  mattr_accessor :impersonation_enabled
  @@impersonation_enabled = false

  mattr_accessor :impersonation_user_models
  @@impersonation_user_models = []

  def self.setup
    yield self
  end

end
