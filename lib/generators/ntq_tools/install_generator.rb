module NtqTools
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
    
      def copy_initializer_file
        template "ntq_tools.rb", "config/initializers/ntq_tools.rb"
      end
    end
  end
end
