# Copyright 2014, Igor Sepelev aka goga63
# Copyright 2015, Yurij Kulchevich aka yorik1984
# All Rights Reserved
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------------
# License: GPL V.3
# Author: Igor Sepelev aka goga63
# Name: add_attribute.rb
# Version: 1.2
# Description: Plugin add attributes of components in model
# Usage: see in menu Help in Extension >  Add attribute > Help
# History:
# 1.0 Initial release 21-July-2014
# by Igor Sepelev aka goga63
# 1.1-beta 10-November-2015
# by Yurij Kulchevich aka yorik1984
#  - add english version of dialogs
#  - add toolbar icon
#  - validate input
# 1.2 -beta release 28-November-2015
#  - change icon size
#  - some bugfix
#  - add component nesting levels
#  - add Help content
# 1.2  30-November-2015 - First public version
# ------------------------------------------------------------------------------

require 'sketchup.rb'

module AddAttributes

  class AddAttributeInputbox

    attr_accessor :prompts, :defaults, :list, :inputbox_window_name, :recursive_level, :recursive_level_list

    def initialize
      @prompts_all = { label: "Name",
                       formlabel: "Display label",
                       units: "Display in",
                       value: "Value or formula ( = )",
                       formulaunits: "Units",
                       access: "Display rule",
                       options: "List Option (&&Opt1=Val1&&Opt2=Val2&&)",
                       lengthunits: "Toggle Units",
                       duplicate: "Duplicate attribute name",
                       recursive: "Component nesting levels (biggest = All)",
                       report: "Report",
                       scale_x: "Scale along red. (X)",
                       scale_y: "Scale along green. (Y)",
                       scale_z: "Scale along blue. (Z)",
                       scale_x_z: "Scale in red/blue plane. (X+Z)",
                       scale_y_z: "Scale in green/blue plane. (Y+Z)",
                       scale_x_y: "Scale in red/green plane. (X+Y)",
                       scale_x_y_z: "Scale uniform (from corners). (XYZ)" }
      @prompts = [ @prompts_all[:label],
                   @prompts_all[:formulaunits],
                   @prompts_all[:access],
                   @prompts_all[:formlabel],
                   @prompts_all[:units],
                   @prompts_all[:value],
                   @prompts_all[:options] ]
      @defaults = ["",
                   "Text",
                   "User can't see this attribute",
                   "",
                   "End user's model units",
                   "",
                   "" ]
      @list = ["",
               "Decimal Number|Text|Inches|Centimeters",
               "User can't see this attribute|User can see this attribute|User can edit as a textbox|User can select from a list",
               "",
               "End user's model units|Whole Number|Decimal Number|Percentage|True/False|Text|Inches|Decimal Feet|Millimeters|Centimeters|Meters|Degrees|Dollars|Euros|Yen|Pounds (weight)|Kilograms",
               "",
               "" ]
      @inputbox_window_name = "Input attributes"
      @recursive_level_list = "2"
      @recursive_level = 1
      @inputbox = []
    end

    def valid_attribute_name(input)
      # Inspect attribute name
      valid_status = []
      status_error = { NO_ERROR: "Input attribute name correct",
                       EMPTY_FIELD: "Attribute name can't be empty",
                       CONTAIN_SPACES: "Attribute name can't contain spaces",
                       NOT_LETTER_OR_NUMBER: "Attribute name can only contain Latin letters and numbers",
                       UNDERSCOPE: "Attribute name can't begin with an underscore",
                       NUMBER_IN_BEGIN: "Attribute name can't begin with an number",
                       TRUE_OR_FALSE: "You may not name an attribute TRUE or FALSE" }
      if input.to_s == ""
        valid_status[0] = false
        valid_status[1] = status_error[:EMPTY_FIELD]
        return valid_status
      end
      regex_space = /(\s)/
      if input =~ regex_space
        valid_status[0] = false
        valid_status[1] = status_error[:CONTAIN_SPACES]
        return valid_status
      end
      special = "?<>',./[]=-)(*&^%$#`~{}\""
      regex_special = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
      regex_latin = /\p{Latin}/
      if input =~ regex_special || !(input.to_s =~ regex_latin)
        valid_status[0] = false
        valid_status[1] = status_error[:NOT_LETTER_OR_NUMBER]
        return valid_status
      end
      if input[0].to_s == "_"
        valid_status[0] = false
        valid_status[1] = status_error[:UNDERSCOPE]
        return valid_status
      end
      regex_digits = /(\d)/
      if input[0].to_s=~ regex_digits
        valid_status[0] = false
        valid_status[1] = status_error[:NUMBER_IN_BEGIN]
        return valid_status
      end
      if input.downcase == "true" || input.downcase == "false"
        valid_status[0] = false
        valid_status[1] = status_error[:TRUE_OR_FALSE]
        return valid_status
      end
      valid_status[0] = true
      valid_status[1] = status_error[:NO_ERROR]
      return valid_status
    end # valid_attribute_name

    def recursive_level_search(selection, level)
      selection.each do |entity|
        definition = AddAttributes::get_definition(entity)
        next if definition.nil?
        recursive_level_search(definition.entities, level+1) + 1
      end
      @recursive_level = level if level > @recursive_level
      return 1
    end

    def inputbox(choice, selection)
      if choice == "Custom..."
        input_check = []
        input_check[0] = false
        until input_check[0]
          custom_name = UI.inputbox(["Custom attribute name (String)"], [""], [""], "Custom attribute name")
          input_check = valid_attribute_name(custom_name[0])
          if !input_check[0]
            UI.messagebox("Failure!"+ "\n" + input_check[1])
          end
        end
        custom_is_standart = standart_attribute(custom_name[0])
        if custom_is_standart[0]
          choice = custom_is_standart[1]
        else
          @inputbox_window_name = "Input Custom attribute"
          @prompts[7] = @prompts_all[:lengthunits]
          @defaults[0] = custom_name[0]
          @defaults[7] = "CENTIMETERS"
          @list[0] = custom_name[0]
          @list[7] = "INCHES|CENTIMETERS"
        end
      end
      case choice
      when "Name", "Summary", "Description", "ItemCode"
        @inputbox_window_name = "Input Component Info attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:value] ]
        @defaults = [ choice,
                      "User can see this attribute" ,
                      "" ]
        @list = [ choice,
                  "User can see this attribute",
                  "" ]
      when "X","Y","Z","LenX","LenY", "LenZ"
        if choice == "X" || choice == "Y" || choice == "Z"
          @inputbox_window_name = "Input Position attribute " + choice
        else
          @inputbox_window_name = "Input Size attribute " + choice
        end
        @prompts[7] = @prompts_all[:lengthunits]
        @defaults[0] = choice
        @defaults[1] = "Centimeters"
        @defaults[4] = "Millimeters"
        @defaults[7] = "CENTIMETERS"
        @list[0] = choice
        @list[1] = "Inches|Centimeters"
        @list[4] = "End user's model units|Inches|Decimal Feet|Millimeters|Centimeters|Meters"
        @list[7] = "INCHES|CENTIMETERS"
      when "RotX", "RotY", "RotZ"
        @inputbox_window_name = "Input Rotation attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:formlabel],
                     @prompts_all[:units],
                     @prompts_all[:value],
                     @prompts_all[:options] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "",
                      "Degrees",
                      "",
                      "" ]
        @list = [ choice,
                  "User can't see this attribute|User can see this attribute|User can edit as a textbox|User can select from a list",
                  "",
                  "Degrees",
                  "",
                  "" ]
      when "Material"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:formlabel],
                     @prompts_all[:units],
                     @prompts_all[:value],
                     @prompts_all[:options] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "",
                      "Text",
                      "",
                      "" ]
        @list = [ choice,
                  "User can't see this attribute|User can see this attribute|User can edit as a textbox|User can select from a list",
                  "",
                  "Text",
                  "",
                  "" ]
      when "ScaleTool"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:scale_x],
                     @prompts_all[:scale_y],
                     @prompts_all[:scale_z],
                     @prompts_all[:scale_x_z],
                     @prompts_all[:scale_y_z],
                     @prompts_all[:scale_x_y],
                     @prompts_all[:scale_x_y_z] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes" ]
        @list = [ choice,
                  "User can't see this attribute",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No" ]
      when "Hidden"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:value] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "0"]
        @list = [ choice,
                  "User can't see this attribute",
                  "" ]
      when "onClick"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts_all[:formlabel] = "Tool tip"
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:formlabel],
                     @prompts_all[:value] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "Click to activate",
                      "" ]
        @list = [ choice,
                  "User can't see this attribute",
                  "",
                  "" ]
      when "Copies", "ImageURL"
        if choice == "Copies"
          @inputbox_window_name = "Input Behaviors attribute " + choice
        else
          @inputbox_window_name = "Input Form Design attribute " + choice
        end
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:value] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "" ]
        @list = [ choice,
                  "User can't see this attribute",
                  "" ]
      when "DialogWidth", "DialogHeight"
        @inputbox_window_name = "Input Form Design attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:value] ]
        @defaults = [ choice,
                      "User can't see this attribute",
                      "400" ]
        @list = [ choice,
                  "User can't see this attribute",
                  "" ]
      when "Toggle Units"
        @prompts = [ @prompts_all[:lengthunits] ]
        @defaults = [ "CENTIMETERS" ]
        @list = [ "INCHES|CENTIMETERS" ]
      else
        nil
      end # case choice
      recursive_level_search(selection, @recursive_level)
      if @recursive_level > 2
        for i in 3..@recursive_level
          @recursive_level_list += "|#{i}"
        end
      end
      @prompts = @prompts + [ @prompts_all[:duplicate], @prompts_all[:recursive], @prompts_all[:report] ]
      @defaults = @defaults + [ "Ignore", "2", "Off" ]
      @list = @list + [ "Ignore|Replace|Equal replace", @recursive_level_list, "Off|Short in messagebox|Full in console" ]
      @inputbox = UI.inputbox(@prompts, @defaults, @list, @inputbox_window_name)
      @inputbox[0] = @inputbox[0]
      input_labels = {}
      @inputbox.each_index do |index|
        temp = { @prompts_all.key(@prompts[index]) => @inputbox[index] }
        input_labels = input_labels.merge(temp)
      end
      return input_labels
    end

    def standart_attribute(attribute)
      label_std = { name: "Name",
                    summary: "Summary",
                    description: "Description",
                    itemcode: "ItemCode",
                    x: "X",
                    y: "Y",
                    z: "Z",
                    lenx: "LenX",
                    leny: "LenY",
                    lenz: "LenZ",
                    rotx: "RotX",
                    roty: "RotY",
                    rotz: "RotZ",
                    material: "Material",
                    scaletool: "ScaleTool",
                    hidden: "Hidden",
                    onclick: "onClick",
                    copies: "Copies",
                    imageurl: "ImageURL",
                    dialogwidth: "DialogWidth",
                    dialogheight: "DialogHeight" }
      standart_attribute_status = []
      key = attribute.to_s.downcase.to_sym
      if label_std.has_key?(key)
        standart_attribute_status[0] = true
        standart_attribute_status[1] = label_std.fetch(key)
      else
        standart_attribute_status[0] = false
        standart_attribute_status[1] = attribute.to_s
      end
      standart_attribute_status
    end

  end # class AddAttribute

  def self.include_element?(array, element)
    array.each_index do |index|
      if array[index] == element
        return true
      end
    end
    return false
  end

  def self.select_components_messagebox?(selection)
    if !selection.empty?
      selection.each do |entity|
        if !entity.is_a?(Sketchup::ComponentInstance)
          UI.messagebox("Select only components")
          return false
        end
      end
    else
      UI.messagebox("Select nothing")
      return false
    end
    true
  end

  def self.get_definition(entity)
    if entity.is_a?(Sketchup::ComponentInstance)
      entity.definition
    elsif entity.is_a?(Sketchup::Group)
      entity.entities.parent
    else
      nil
    end
  end

  def self.recursive_set_dynamic_attributes(selection, input, duplicate_status, recursive_level, current_nested_level = 2, listing_components = [])
    dict = "dynamic_attributes"
    selection.each do |entity|
      definition = self.get_definition(entity)
      next if definition.nil?
      instance_attribute = entity.get_attribute dict, input[:label].to_s.downcase
      definition_attribute = entity.definition.get_attribute dict, input[:label].to_s.downcase
      if current_nested_level <= recursive_level
        if entity.is_a?(Sketchup::ComponentInstance)
          separator = "  "
          if current_nested_level > 2
            for i in 3..current_nested_level
              separator += "| "
            end
          end
          level = current_nested_level.to_s + separator
          case duplicate_status
          when "Replace"
            self.set_dynamic_attributes(entity, input)
            listing_components += ["#{level[0,3]}#{separator}#{entity.definition.name}"]
          when "Ignore"
            if instance_attribute == nil || definition_attribute == nil
              self.set_dynamic_attributes(entity, input)
              listing_components += ["#{level[0,3]}#{separator}#{entity.definition.name}"]
            end
          when "Equal replace"
            if instance_attribute != nil || definition_attribute != nil
              self.set_dynamic_attributes(entity, input)
              listing_components += ["#{level[0,3]}#{separator}#{entity.definition.name}"]
            end
          else
            nil
          end
        end
      end
      listing_components = self.recursive_set_dynamic_attributes(definition.entities, input, duplicate_status,recursive_level, current_nested_level + 1, listing_components)
    end
    listing_components
  end # recursive_set_dynamic_attributes

  def self.set_dynamic_attributes(entity, input)
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
    attributes_access = { NONE: "User can't see this attribute",
                          VIEW: "User can see this attribute",
                          TEXTBOX: "User can edit as a textbox",
                          LIST: "User can select from a list" }
    label_input = input[:label].to_s.downcase
    dict = "dynamic_attributes"
    definition_name = entity.definition.name.to_s
    dynamic_attributes_name = entity.get_attribute(dict, "_name")

    if dynamic_attributes_name == nil
      entity.set_attribute dict, "_name", definition_name
      entity.definition.set_attribute dict, "_name", definition_name
    end

    wide_label = ["X", "Y", "Z", "RotX", "RotY", "RotZ", "Copies"]
    without_access = ["Name", "Summary", "Description", "ItemCode", "Material", "ScaleTool", "Hidden", "onClick", "Copies","DialogWidth", "DialogHeight"]
    wide_formlabel = ["X", "Y", "Z", "RotX", "RotY", "RotZ", "Copies"]
    standart = AddAttributeInputbox.new
    input_is_standart = standart.standart_attribute(input[:label].to_s)

    if input.has_key?("label".to_sym)
      if self.include_element?(wide_label, input[:label].to_s)
        entity.set_attribute dict, "_#{label_input}_label", input[:label].to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_label", input[:label].to_s
      else
        entity.definition.set_attribute dict, "_#{label_input}_label", input[:label].to_s
      end
    end

    if input.has_key?("access".to_sym) && !self.include_element?(without_access, input[:label].to_s)
      if self.include_element?(wide_label, input[:label].to_s)
        entity.set_attribute dict, "_#{label_input}_access", attributes_access.key(input[:access]).to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_access", attributes_access.key(input[:access]).to_s
      else
        entity.definition.set_attribute dict, "_#{label_input}_access", attributes_access.key(input[:access]).to_s
      end
    end

    if input.has_key?("value".to_sym)
      if input[:units].to_s.length != 0 && !self.include_element?(without_access, input[:label].to_s)
        if self.include_element?(wide_label, input[:label].to_s)
          entity.set_attribute dict, "_#{label_input}_units", attributes_units.key(input[:units]).to_s
          entity.definition.set_attribute dict, "_inst__#{label_input}_units", attributes_units.key(input[:units]).to_s
        else
          entity.definition.set_attribute dict, "_#{label_input}_units", attributes_units.key(input[:units]).to_s
        end
      end
    end


    if input[:formlabel].to_s.length != 0
      if self.include_element?(wide_formlabel, input[:label].to_s)
        entity.set_attribute dict, "_#{label_input}_formlabel", input[:formlabel].to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_formlabel", input[:formlabel].to_s
      elsif !self.include_element?(without_access, input[:label].to_s)
        entity.definition.set_attribute dict, "_#{label_input}_formlabel", input[:formlabel].to_s
      end
    end
    result_value = input[:value]
    unless result_value == nil
      value_zero = result_value[0].to_s
      value_formula = result_value[1..result_value.length].to_s
      if input[:formulaunits].to_s.length != 0
        case input[:formulaunits].to_s
        when "Inches"
          result_value = input[:value].to_f*1.to_inch
        when "Centimeters"
          result_value = input[:value].to_f*(1.to_inch/1.to_cm)
        else
          result_value = input[:value]
        end
        if self.include_element?(wide_formlabel, input[:label].to_s)
          entity.set_attribute dict, "_#{label_input}_formulaunits", attributes_formulaunits.key(input[:formulaunits]).to_s
        else
          entity.definition.set_attribute dict, "_#{label_input}_formulaunits", attributes_formulaunits.key(input[:formulaunits]).to_s
        end
      end
      if value_zero == "="
        if self.include_element?(wide_label, input[:label].to_s)
          entity.set_attribute dict, "_#{label_input}_formula", value_formula
          entity.definition.set_attribute dict, "_inst__#{label_input}_formula", value_formula
          entity.definition.set_attribute dict, "_inst_#{label_input}", result_value.to_f
          entity.set_attribute dict, label_input, result_value.to_f
        else
          entity.definition.set_attribute dict, "_#{label_input}_formula", value_formula
          entity.set_attribute dict, label_input, result_value.to_f
          entity.definition.set_attribute dict, label_input, result_value.to_f
        end
      else
        if self.include_element?(wide_label, input[:label].to_s)
          entity.set_attribute dict, "_#{label_input}_formula", input[:value].to_f.to_s
          entity.definition.set_attribute dict, "_inst__#{label_input}_formula", input[:value].to_f.to_s
          # REDRAW
          $dc_observers.get_latest_class.redraw_with_undo(entity) if input_is_standart[0]
          entity.delete_attribute dict, "_#{label_input}_formula"
          entity.definition.delete_attribute dict, "_inst__#{label_input}_formula"
          entity.definition.set_attribute dict, "_inst_#{label_input}", result_value.to_f.to_s
          entity.set_attribute dict, label_input, result_value.to_f.to_s
          entity.definition.set_attribute dict, "_inst__#{label_input}_formula", "null"
        else
          entity.definition.set_attribute dict, "_#{label_input}_formula", input[:value].to_f.to_s
          # REDRAW
          $dc_observers.get_latest_class.redraw_with_undo(entity) if input_is_standart[0]
          entity.definition.delete_attribute dict, "_#{label_input}_formula"
          entity.set_attribute dict, label_input, result_value.to_f.to_s
          entity.definition.set_attribute dict, label_input, result_value.to_f.to_s
        end
      end
    end
    if input[:options].to_s.length != 0
      entity.set_attribute dict , "_#{label_input}_options", input[:options].to_s
    end

    if input.has_key?("lengthunits".to_sym)
      entity.set_attribute dict, "_lengthunits", input[:lengthunits].to_s
      entity.definition.set_attribute dict, "_lengthunits", input[:lengthunits].to_s
    elsif entity.get_attribute(dict, "_lengthunits") == nil
      entity.set_attribute dict, "_lengthunits", "INCHES"
      entity.definition.set_attribute dict, "_lengthunits", "INCHES"
    end


    case input[:label].to_s
    when "ScaleTool"
      scaletool_binary = ""
      input.each_value do |value|
        scaletool_binary = scaletool_binary + "0" if value == "Yes"
        scaletool_binary = scaletool_binary + "1" if value == "No"
      end
      scaletool_dec = scaletool_binary.reverse.to_i(2).to_s
      entity.set_attribute dict, "scaletool", scaletool_dec
      entity.definition.set_attribute dict, "scaletool", scaletool_dec
      entity.definition.set_attribute dict, "_scaletool_label", "ScaleTool"
      entity.definition.set_attribute dict, "_scaletool_formlabel", "ScaleTool"
      entity.definition.set_attribute dict, "_scaletool_units", "STRING"
    when "Hidden"
      entity.definition.set_attribute dict, "_hidden_formlabel", "Hidden"
      entity.definition.set_attribute dict, "_hidden_units", "BOOLEAN"
    when "onClick"
      entity.definition.set_attribute dict, "_onclick_units", "STRING"
    when "Copies"
      entity.set_attribute dict, "_copies_formlabel", "Copies"
      entity.set_attribute dict, "_copies_units", "INTEGER"
      entity.definition.set_attribute dict, "_inst__copies_units", "INTEGER"
    when "DialogWidth", "DialogHeight"
      entity.definition.set_attribute dict, "_#{label_input}_formlabel", input[:label].to_s
      entity.definition.set_attribute dict, "_#{label_input}_units", "INTEGER"
    else
      nil
    end

    #REDRAW
    $dc_observers.get_latest_class.redraw_with_undo(entity) if input_is_standart[0]
  end # set_dynamic_attributes

  def self.inputbox_attributes
    model = Sketchup.active_model
    selection = model.selection
    if select_components_messagebox?(selection)
      input = []
      prompts = ["Attribute Name"]
      defaults = ["Custom..."]
      list = ["Custom...|Name|Summary|Description|ItemCode|X|Y|Z|LenX|LenY|LenZ|RotX|RotY|RotZ|Material|ScaleTool|Hidden|onClick|Copies|ImageURL|DialogWidth|DialogHeight|Toggle Units"]
      choice_attributes = UI.inputbox(prompts, defaults, list, "Choice attributes")
      choice = choice_attributes[0].to_s
      attribute_inputbox = AddAttributeInputbox.new
      input = attribute_inputbox.inputbox(choice, selection)
      model.start_operation('Adding attribute', true)
      duplicate_status = input[:duplicate].to_s
      recursive_level = input[:recursive].to_i
      report = input[:report].to_s
      total_count = self.recursive_set_dynamic_attributes(selection, input, duplicate_status, recursive_level)
      case report
      when "Short in messagebox"
        UI.messagebox("Attribute \" #{input[:label].to_s}\" has been added to #{total_count.length} component(s)")
      when "Full in console"
        puts "========================================"
        puts "Attribute \"#{input[:label].to_s}\""
        puts "----------------------------------------"
        puts "#{total_count.length} component(s)"
        puts "========================================"
        puts total_count
        puts "========================================"
      else
        nil
      end
      model.commit_operation
    end
  end # inputbox_attributes

  def self.help_information
    # open help content in browser
    plugins = Sketchup.find_support_file "Plugins/"
    help_file_folder = "add_attribute/help/"
    help_file = File.join(plugins, help_file_folder, "help.html" )
    if (help_file)
      UI.openURL "file://" + help_file
    else
      UI.messagebox "Failure"
    end
  end

  # Create menu items
  unless file_loaded?(__FILE__)
    # Create toolbar
    add_attribute_tb = UI::Toolbar.new(AddAttributes::PLUGIN_NAME)
    icon_s_inputbox_attributes = File.join(AddAttributes::PATH_ICONS, "inputbox_attributes_24.png")
    icon_inputbox_attributes = File.join(AddAttributes::PATH_ICONS, "inputbox_attributes_36.png")

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
    add_attribute.add_item("Help") {AddAttributes::help_information}
  end

end # module AddAttributes

file_loaded(__FILE__)
