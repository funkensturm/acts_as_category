plugin_path = File.dirname __FILE__

# Loading localization files
I18n.load_path += Dir[File.join(plugin_path, 'config', 'locales', '*.{rb,yml}')]

require 'acts_as_category/version'
require 'acts_as_category/acts_as_category'
require 'acts_as_category/acts_as_category_content'
require 'acts_as_category/acts_as_category_helper'

# Loading Helper
ActionView::Base.class_eval 'include ActsAsCategoryHelper'

# Loading acts_as_*
ActiveRecord::Base.class_eval 'include ActsAsCategory'
ActiveRecord::Base.class_eval 'include ActsAsCategoryContent'
