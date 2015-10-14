# Copyright 2014, Igor Sepelev aka goga63
# All Rights Reserved
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------------
# License: GPL V.3
# Author: Igor Sepelev aka goga63
# Name: add_attribute.rb
# Version: 2.0
# Description: Plugin add attributes of components in model
# Usage: see README
# History:
# 1.0 Initial release
# by Igor Sepelev aka goga63
#
# 2.0 11-October-2015
# by Yurij Kulchevich
#  - add english version of dialogs and toolbar icon;
#  - import data from CSV file.
#------------------------------------------------------------------------------

require 'sketchup.rb'

module AddAttributes

  def self.select_components_messagebox?(selection)
    if !selection.empty?
      selection.each do |entity|
        if entity.class != Sketchup::ComponentInstance
          UI.messagebox("Select only components")
          return false
          nil
        end
      end
    else
      UI.messagebox("Select nothing")
      return false
      nil
    end
    true
  end

  def self.recursive_count_attr(entity,input)
    if (entity.typename == "Face") || (entity.typename == "Edge")
      simple = 0
      complex = 0
      if (entity.class == Sketchup::ComponentInstance)
        for i in 0..entity.definition.entities.count - 1
          if component_instance?(entity.definition.entities[i])
            simple = simple + 1
          else
            complex = complex + 1
            recursive_count_attr(entity.definition.entities[i])
          end
        end
      end
      if (simple > 0) && (complex == 0)
        set_attributes(entity,input)
      end
    end
  end

  def self.set_attributes(entity ,input)
    attributes_formulaunits = { FLOAT: "Decimal Number",
                               STRING: "Text",
                               INCHES: "Inches",
                          CENTIMETERS: "Centimeters" }
    attributes_units = { DEFAULT: "End user\'s model units",
                         INTEGER: "Whole Number",
                           FLOAT: "Decimal Number",
                         PERCENT: "Percentage",
                         BOOLEAN: "True/False",
                          STRING: "Text",
                          INCHES: "Inches",
                            FEET: "Decimal Feet",
                     MILLIMETERS: "Millimeters",
                     CENTIMETERS: "Centimeters",
                          METERS: "Meters",
                         DEGREES: "Degrees",
                         DOLLARS: "Dollars",
                           EUROS: "Euros",
                             YEN: "Yen",
                          POUNDS: "Pounds (weight)",
                       KILOGRAMS: "Kilograms" }
    attributes_access = { NONE: "User cannot see this attribute",
                          VIEW: "User can see this attribute",
                       TEXTBOX: "User can edit as a textbox",
                          LIST: "User can select from a list" }
    entity.set_attribute 'dynamic_attributes', "_" + input[0] +"_label", input[0]
    entity.set_attribute 'dynamic_attributes', ("_" + input[0] + "_formlabel"), input[1]
    entity.set_attribute 'dynamic_attributes', "_" + input[0] +"_units", attributes_units.key(input[2]).to_s
    entity.set_attribute 'dynamic_attributes', "_" + input[0] + "_formulaunits", attributes_formulaunits.key(input[4]).to_s
    entity.set_attribute 'dynamic_attributes', "_" + input[0] + "_access", attributes_access.key(input[5]).to_s
    if input[6] != nil
      entity.set_attribute 'dynamic_attributes' , "_" + input[0] + "_options", input[6]
    end
    entity.set_attribute 'dynamic_attributes', '_lengthunits', input[7]
    case input[2].to_s
    when "Millimeters"
      result_units = input[3].to_f*(1.to_inch/1.to_mm)
    when "Centimeters"
      result_units = input[3].to_f*(1.to_inch/1.to_cm)
    when "Meters"
      result_units = input[3].to_f*(1.to_inch/1.to_m)
    else
      result_units = input[3]
    end
    entity.set_attribute 'dynamic_attributes', input[0], result_units
    UI.messagebox("Attributes set success!")
  end #set_attributes

  def self.inputbox_attributes
    model = Sketchup.active_model
    selection = model.selection
    if select_components_messagebox?(selection)
      prompts = ["Name",
                 "Display label",
                 "Display in",
                 "Value",
                 "Units",
                 "Display rule",
                 "List Option (Option = Value)",
                 "Toggle Units"]
      defaults = ["",
                  "",
                  "End user\'s model units",
                  "",
                  "Text",
                  "User cannot see this attribure",
                  "",
                  "CENTIMETERS"]
      list = ["",
              "",
              "End user\'s model units|Whole Number|Decimal Number|Percentage|True/False|Text|Inches|Decimal Feet|Millimeters|Centimeters|Meters|Degrees|Dollars|Euros|Yen|Pounds (weight)|Kilograms",
              "",
              "Decimal Number|Text|Inches|Centimeters",
              "User cannot see this attribure|User can see this attribure|User can edit as a textbox|User can select from a list",
              "",
              "INCHES|CENTIMETERS"]
      input = UI.inputbox(prompts, defaults, list, "Input attributes")
      status = model.start_operation('Adding attribute', true)
      selection.each { |entity| set_attributes(entity, input) }
      model.commit_operation
    end
  end

end  # module AddAttributes

# Create menu items
unless file_loaded?(__FILE__)
  # Create toolbar
  plugins = Sketchup.find_support_file "Plugins/"
  icons_folder = "add_attribute/icons/"
  add_attribute_tb = UI::Toolbar.new("Add attribute")
  icon_s_inputbox_attributes = File.join(plugins, icons_folder, "inputbox_attributes_16.png")
  icon_inputbox_attributes = File.join(plugins, icons_folder, "inputbox_attributes_24.png")

  # Add item "inputbox_attributes"
  inputbox_attributes_cmd = UI::Command.new("Adding new attribute from inputbox"){ AddAttributes::inputbox_attributes }
  inputbox_attributes_cmd.small_icon = icon_s_inputbox_attributes
  inputbox_attributes_cmd.large_icon = icon_inputbox_attributes
  inputbox_attributes_cmd.tooltip = "Adding new attributes from inputbox"
  inputbox_attributes_cmd.status_bar_text = "Adding new attributes from inputbox"

  add_attribute_tb.add_item(inputbox_attributes_cmd)

  # Create menu
  add_attribute = UI.menu("Plugins").add_submenu("Add attribute")
  add_attribute.add_item("Add attributes inputbox"){ AddAttributes::inputbox_attributes }
  file_loaded(__FILE__)
end
