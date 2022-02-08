# frozen_string_literal: true

# Loader for add_attribute/add_attribute.rb

require 'sketchup'
require 'extensions'

version_required = 14

if Sketchup.version.to_f >= version_required
  if Sketchup.is_pro?

    module AddAttributes

      PLUGIN_ID       = 'AddAttributes'
      PLUGIN_NAME     = 'Add attribute'
      PLUGIN_VERSION  = '2.0'

      # https://github.com/SketchUp/rubocop-sketchup/blob/main/manual/cops_suggestions.md#fileencoding
      file = __FILE__.dup
      file.force_encoding('UTF-8') if file.respond_to?(:force_encoding)

      FILENAMESPACE = File.basename(file, '.rb')
      PATH_ROOT     = File.dirname(file)
      PATH          = File.join(PATH_ROOT, FILENAMESPACE)
      PATH_ICONS    = File.join(PATH, 'icons')
      PATH_HELP     = File.join(PATH, 'help')

      unless file_loaded?(file)
        loader                    = File.join(PATH, 'core.rb')
        add_attribute             = SketchupExtension.new(PLUGIN_NAME, loader)
        add_attribute.description = 'Plugin add attributes of components in model'
        add_attribute.version     = PLUGIN_VERSION
        add_attribute.copyright   = 'Copyright 2022 by Igor Sepelev and Yurij Kulchevich'
        add_attribute.creator     = 'Igor Sepelev'
        Sketchup.register_extension(add_attribute, true)
        file_loaded(file)
      end
    end

  else
    UI.messagebox('Plugin «Add attribute» work only in PRO version of Sketchup. Visit sketchup.com to upgrade.')
  end
else
  UI.messagebox("Plugin «Add attribute» doesn't work in this version of Sketchup. Please, install \
    Sketchup version 20#{version_required} or above to run this plugin. Visit sketchup.com to upgrade.")
end
