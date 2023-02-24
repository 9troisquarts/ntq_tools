require_relative "lib/ntq_tools/version"

Gem::Specification.new do |spec|
  spec.name        = "ntq_tools"
  spec.version     = NtqTools::VERSION
  spec.authors     = ["Kevin"]
  spec.email       = ["kevin@9troisquarts.com"]
  spec.homepage    = "https://github.com"
  spec.summary     = "Boite à outil de 9troisquarts"
  spec.description = "Boite à outil de 9troisquarts"
  spec.license     = "MIT"
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com"
  spec.metadata["changelog_uri"] = "https://github.com"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "< 8", ">= 6"
  spec.add_dependency "missing_translation", "< 1.0.0"
end
