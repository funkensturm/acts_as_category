# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_category/version'

Gem::Specification.new do |spec|
  spec.name          = 'acts_as_category'
  spec.version       = ActsAsCategory::VERSION
  spec.authors       = ['Manuel Wiedenmann']
  spec.summary       = %q{acts_as_category provides a tree structure for infinite categories and their subcategories (similar to acts_as_tree).}
  spec.description   = %q{Each user can have his own set of category trees using the
`:scope` feature
-   It validates that no category will be the parent of its own
    descendant and all other variations of these foreign key things
-   You can define which hidden categories should still be permitted to
    the current user (through a simple class variable, thus it can
    easily be set per user)
-   There is a variety of instance methods such as `ancestors`,
    `descendants`, `descendants_ids`, `root?`, etc.
-   It has view helpers to create menus, select boxes, drag and drop
    ajax lists, etc.
-   It optionally provides sorting by a position column per hierarchy
    level, including administration methods that take parameters from
    the helpers
-   There are automatic cache columns for children, ancestors and
    descendants (good for fast menu output)
-   I18n localization for individual error messages
-   All options (e.g. database field names)
    highly configurable via a simple hash}
  spec.homepage      = 'https://github.com/funkensturm/acts_as_category'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'activerecord', '~> 3.2.0'
end
