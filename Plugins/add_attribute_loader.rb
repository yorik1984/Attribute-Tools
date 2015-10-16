# Loader for add_attribute/add_attribute.rb

require 'sketchup.rb'
require 'extensions.rb'

module AddAttributes

  PLUGIN_ID       = 'AddAttributes'.freeze
  PLUGIN_NAME     = 'Add attribute'.freeze
  PLUGIN_VERSION  = '1.1'.freeze

  FILENAMESPACE = File.basename(__FILE__, '.*')
  PATH_ROOT     = File.dirname(__FILE__).freeze
  PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze
  unless file_loaded?(__FILE__)
    loader = File.join( PATH, 'add_attribute.rb' )
    ex             = SketchupExtension.new(PLUGIN_NAME, loader)
    ex.description = 'Plugin add attributes of components in model'
    ex.version     = PLUGIN_VERSION
    ex.copyright   = 'Copyright 2014 by Igor Sepelev aka goga63 and Yurij Kulchevich (english version)'
    ex.creator     = 'Igor Sepelev aka goga63'
    Sketchup.register_extension (add_attribute, true)
  end
end

file_loaded(__FILE__)
