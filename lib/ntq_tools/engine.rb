module NtqTools
  class Engine < ::Rails::Engine
    isolate_namespace NtqTools
    
    config.autoload_paths << File.expand_path("../../lib", __FILE__)
  end
end
