# Copyright 2014, Igor Sepelev aka goga63
# All Rights Reserved
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------------
# License: GPL V.3
# Author: Igor Sepelev aka goga63
# Name: add_attribute.rb
# Version: 1.1
# Description: Plugin add attributes of components in model
# Usage: see README
# History:
# 1.0 Initial release
# by Igor Sepelev aka goga63
#
# 1.1 16-October-2015
# by Yurij Kulchevich
#  - add english version of dialogs;
#  - add toolbar icon;
#  - validate input.
# ------------------------------------------------------------------------------

require 'sketchup.rb'

module AddAttributes

  def self.valid_attribute_name(selection, input)
    #Inspect attribute name
    valid_status = []
    status_error = { NO_ERROR: "Input attribute name correct",
                  EMPTY_FIELD: "Attribute name cannot be empty",
               CONTAIN_SPACES: "Attribute name cannot contain spaces",
         NOT_LETTER_OR_NUMBER: "Attribute name can only contain letters and numbers",
                   UNDERSCOPE: "Attribute name cannot begin with an underscore",
              NUMBER_IN_BEGIN: "Attribute name cannot begin with an number",
                TRUE_OR_FALSE: "You may not name an attribute TRUE or FALSE" }

    if input.to_s == ""
      valid_status[0] = false
      valid_status[1] = status_error[:EMPTY_FIELD]
      return valid_status
      nil
    end

    special_space = " "
    regex_space = /[#{special_space.gsub(/./){|char| "\\#{char}"}}]/
    if input =~ regex_space
      valid_status[0] = false
      valid_status[1] = status_error[:CONTAIN_SPACES]
      return valid_status
      nil
    end

    special = "?<>',./[]=-)(*&^%$#`~{}\""
    regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
    if input =~ regex
      valid_status[0] = false
      valid_status[1] = status_error[:NOT_LETTER_OR_NUMBER]
      return valid_status
      nil
    end

     if input[0].to_s == "_"
      valid_status[0] = false
      valid_status[1] = status_error[:UNDERSCOPE]
      return valid_status
      nil
    end

    if input[0].to_l
      valid_status[0] = false
      valid_status[1] = status_error[:NUMBER_IN_BEGIN]
      return valid_status
      nil
    end

    if input.downcase == "true" || input.downcase == "false"
      valid_status[0] = false
      valid_status[1] = status_error[:TRUE_OR_FALSE]
      return valid_status
      nil
    end

    valid_status[0] = true
    valid_status[1] = status_error[:NO_ERROR]
    return valid_status
  end # valid_attribute_name

  def self.get_definition(entity)
    if entity.is_a?(Sketchup::ComponentInstance)
      entity.definition
    elsif entity.is_a?(Sketchup::Group)
      entity.entities.parent
    else
      nil
    end
  end

  def self.select_components_messagebox?(selection)
    if !selection.empty?
      selection.each do |entity|
        if !entity.is_a?(Sketchup::ComponentInstance)
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

 def self.set_attributes(entity ,input)
    attributes_formulaunits = { FLOAT: "Decimal Number",
                               STRING: "Text",
                               INCHES: "Inches",
                          CENTIMETERS: "Centimeters" }
    attributes_units = { DEFAULT: "End user's model units",
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
    entity.set_attribute "dynamic_attributes", "_" + input[0] +"_label", input[0]
    entity.set_attribute "dynamic_attributes", ("_" + input[0] + "_formlabel"), input[1]
    entity.set_attribute "dynamic_attributes", "_" + input[0] +"_units", attributes_units.key(input[2]).to_s
    entity.set_attribute "dynamic_attributes", "_" + input[0] + "_formulaunits", attributes_formulaunits.key(input[4]).to_s
    entity.set_attribute"dynamic_attributes", "_" + input[0] + "_access", attributes_access.key(input[5]).to_s
    if input[6] != nil
      entity.set_attribute "dynamic_attributes" , "_" + input[0] + "_options", input[6]
    end
    entity.set_attribute "dynamic_attributes", "_lengthunits", input[7]
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
    entity.set_attribute "dynamic_attributes", input[0], result_units
  end #set_attributes

  def self.recursive_set_attributes(selection, input)
    selection.each do |entity|
      definition = self.get_definition(entity)
      next if definition.nil?
      set_attributes(entity, input) if entity.is_a?(Sketchup::ComponentInstance)
      self.recursive_set_attributes(definition.entities, input)
    end
  end

  def self.inputbox_attributes
    model = Sketchup.active_model
    selection = model.selection
    if select_components_messagebox?(selection)
      prompts = ["Name (String)",
                 "Display label",
                 "Display in",
                 "Value",
                 "Units",
                 "Display rule",
                 "List Option (Opt1=Val1&&Opt2=Val2)",
                 "Toggle Units",
                 "Duplicate attribute name"]
      defaults = ["",
                  "",
                  "End user's model units",
                  "",
                  "Text",
                  "User cannot see this attribure",
                  "",
                  "CENTIMETERS",
                  "Ignore"]
      list = ["",
              "",
              "End user's model units|Whole Number|Decimal Number|Percentage|True/False|Text|Inches|Decimal Feet|Millimeters|Centimeters|Meters|Degrees|Dollars|Euros|Yen|Pounds (weight)|Kilograms",
              "",
              "Decimal Number|Text|Inches|Centimeters",
              "User cannot see this attribure|User can see this attribure|User can edit as a textbox|User can select from a list",
              "",
              "INCHES|CENTIMETERS",
              "Ignore|Replace"]
      input = UI.inputbox(prompts, defaults, list, "Input attributes")
      input_check = self.valid_attribute_name(selection, input[0])
      if !input_check[0]
        UI.messagebox("Failure!"+ "\n" + input_check[1])
        exit
      end
      status = model.start_operation('Adding attribute', true)
      answer = UI.messagebox("Do you want recursive adding attribute(s)?", MB_YESNO)
      if answer == IDYES
        self.recursive_set_attributes(selection, input)
      else
        selection.each { |entity| self.set_attributes(entity, input) }
      end
      model.commit_operation
    end
  end

end  # module AddAttributes

# Create menu items
unless file_loaded?(__FILE__)
  # Create toolbar
  add_attribute_tb = UI::Toolbar.new(AddAttributes::PLUGIN_NAME)
  icon_s_inputbox_attributes = File.join(AddAttributes::PATH_ICONS, "inputbox_attributes_16.png")
  icon_inputbox_attributes = File.join(AddAttributes::PATH_ICONS, "inputbox_attributes_24.png")

  # Add item "inputbox_attributes"
  inputbox_attributes_cmd = UI::Command.new("Adding new attribute from inputbox"){ AddAttributes::inputbox_attributes }
  inputbox_attributes_cmd.small_icon = icon_s_inputbox_attributes
  inputbox_attributes_cmd.large_icon = icon_inputbox_attributes
  inputbox_attributes_cmd.tooltip = "Adding new attributes from inputbox"
  inputbox_attributes_cmd.status_bar_text = "Adding new attributes from inputbox"

  add_attribute_tb.add_item(inputbox_attributes_cmd)

  # Create menu
  add_attribute = UI.menu("Plugins").add_submenu(AddAttributes::PLUGIN_NAME)
  add_attribute.add_item("Add attributes inputbox"){ AddAttributes::inputbox_attributes }
  file_loaded(__FILE__)
end
