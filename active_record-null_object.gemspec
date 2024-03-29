$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "active_record/null_object/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_record-null_object"
  s.version     = ActiveRecord::NullObject::VERSION
  s.authors     = ["Keegan Leitz"]
  s.email       = ["keegan@openbay.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of ActiveRecord::NullObject."
  s.description = "TODO: Description of ActiveRecord::NullObject."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.0"

  s.add_development_dependency "sqlite3"
end
