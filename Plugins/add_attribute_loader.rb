# Loader for add_attribute/add_attribute.rb

require 'sketchup.rb'
require 'extensions.rb'

add_attribute = SketchupExtension.new "Add attribute", "add_attribute/add_attribute.rb"
add_attribute.copyright = "Copyright 2014 by Igor Sepelev aka goga63 and Yurij Kulchevich (english version)"
add_attribute.version = "1.1"
add_attribute.creator = "Igor Sepelev aka goga63"
add_attribute.description = "Plugin add attributes of components in model"
Sketchup.register_extension add_attribute, true
