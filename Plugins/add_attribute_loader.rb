
# Loader for add_attribute/add_attribute.rb

require 'sketchup.rb'
require 'extensions.rb'

module AddAttributes

  PLUGIN_ID       = 'AddAttributes'.freeze
  PLUGIN_NAME     = 'Add attribute'.freeze
  PLUGIN_VERSION  = '1.1'.freeze

  FILENAMESPACE = File.basename(__FILE__, '_loader.rb')
  PATH_ROOT     = File.dirname(__FILE__).freeze
  PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze
  PATH_ICONS    = File.join(PATH, 'icons').freeze

  unless file_loaded?(__FILE__)
    loader = File.join( PATH, FILENAMESPACE + '.rb' )
    add_attribute             = SketchupExtension.new(PLUGIN_NAME, loader)
    add_attribute.description = 'Plugin add attributes of components in model'
    add_attribute.version     = PLUGIN_VERSION
    add_attribute.copyright   = 'Copyright 2014 by Igor Sepelev aka goga63 and Yurij Kulchevich (english version)'
    add_attribute.creator     = 'Igor Sepelev aka goga63'
    Sketchup.register_extension(add_attribute, true)
  end
end

file_loaded(__FILE__)
