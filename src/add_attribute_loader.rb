# Loader for add_attribute/add_attribute.rb

require 'sketchup.rb'
require 'extensions.rb'

version_required = 14

if Sketchup.version.to_f >= version_required
  if Sketchup.is_pro?

    module AddAttributes

      PLUGIN_ID       = 'AddAttributes'.freeze
      PLUGIN_NAME     = 'Add attribute'.freeze
      PLUGIN_VERSION  = '1.2'.freeze

      FILENAMESPACE = File.basename(__FILE__, '_loader.rb')
      PATH_ROOT     = File.dirname(__FILE__).freeze
      PATH          = File.join(PATH_ROOT, FILENAMESPACE).freeze
      PATH_ICONS    = File.join(PATH, 'icons').freeze

      unless file_loaded?(__FILE__)
        loader = File.join( PATH, FILENAMESPACE + '.rb' )
        add_attribute             = SketchupExtension.new(PLUGIN_NAME, loader)
        add_attribute.description = 'Plugin add attributes of components in model'
        add_attribute.version     = PLUGIN_VERSION
        add_attribute.copyright   = 'Copyright 2014 by Igor Sepelev aka goga63 and Yurij Kulchevich aka yorik1984 (english version, new features)'
        add_attribute.creator     = 'Igor Sepelev aka goga63'
        Sketchup.register_extension(add_attribute, true)
      end

    end

  else
    UI.messagebox("Plugin \"Add attribute\" work only in PRO version of Sketchup. Visit sketchup.com to upgrade.")
  end
else
  UI.messagebox("Plugin \"Add attribute\" doesn't work in this version of Sketchup. Please, install Sketchup version 20#{version_required.to_s} or above to run this plugin. Visit sketchup.com to upgrade.")
end

file_loaded(__FILE__)
