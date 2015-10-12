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
        if !(entity.class == Sketchup::ComponentInstance)
          UI.messagebox("Выберите только компоненты")
          return false
          nil
        end
      end
    else
      UI.messagebox("Ничего не выбрано")
      return false
      nil
    end
    true
  end

  def recursive_count_attr(entity,input)
    if (entity.typename == "Face") || (entity.typename == "Edge")
      simple = 0
      complex = 0
      if (entity.typename == "ComponentInstance")
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

  def set_attributes(entity ,input)
    model.start_operation
    massiv = ["десятичное число","текст","дюймы","сантиметры"]
    attributes_formulaunits = input[4]
    attributes_formulaunits = massiv.index(attributes_formulaunits)
    massiv = ["FLOAT","STRING","INCHES","CENTIMETERS"]
    attributes_formulaunits = massiv[attributes_formulaunits]
    entity.set_attribute'dynamic_attributes',"_" + input[0] + "_formulaunits",attributes_formulaunits.to_s
    massiv = ["использовать единицы модели","целое число","десятичное число","процент","True/False","текст","дюймы","десятичные футы","миллиметры","сантиметры","метры","градусы","доллары","евро","йены","фунты(вес)","килограммы"]
    attributes_units = input[2]
    attributes_units = massiv.index(attributes_units)
    massiv =["DEFAULT","INTEGER","FLOAT","PERCENT","BOOLEAN","STRING","INCHES","FEET","MILLIMETERS","CENTIMETERS","METERS","DEGREES","DOLLARS","EUROS","YEN","POUNDS","KILOGRAMS"]
    attributes_units = massiv[attributes_units]
    entity.set_attribute'dynamic_attributes',"_" + input[0] +"_units",attributes_units.to_s
    entity.set_attribute'dynamic_attributes','_lengthunits',input[7]
    entity.set_attribute'dynamic_attributes',"_" + input[0] +"_label",input[0]
    entity.set_attribute'dynamic_attributes',("_"+ input[0] + "_formlabel"),input[1]
    data_attribute=input[3]
    if input[2] == "миллиметры"
      entity.set_attribute'dynamic_attributes',input[0],(data_attribute.to_f*0.0393700787401575)
      else
        if input[2]=="сантиметры"
        entity.set_attribute'dynamic_attributes',input[0],(data_attribute.to_f*0.393700787401575)
        else
          if (input[2]=="метры")
            entity.set_attribute'dynamic_attributes',input[0],(data_attribute.to_f*39.3700787401575)
          else
            entity.set_attribute'dynamic_attributes',input[0],input[3]
          end
       end
     end
    massiv = ["пользователи не видят атрибут.","пользователи видят атрибут.","ввод в текстовом поле.","выбор из списка."]
    attributes_access =input[5]
    attributes_access =massiv.index(attributes_access)
    massiv = ["NONE","VIEW","TEXTBOX","LIST"]
    attributes_access =massiv[attributes_access]
    entity.set_attribute'dynamic_attributes',"_" + input[0]+"_access",attributes_access.to_s
    if input[6] != nil
      entity.set_attribute'dynamic_attributes',"_" + input[0] + "_options",input[6]
    end
    model.commit_operation
    UI.messagebox("Атрибут успешно установлен!")
  end #set_attributes

  def self.inputbox_attributes
    model = Sketchup.active_model
    selection = model.selection
    if select_components_messagebox?(selection)
      prompts = ["Имя атрибута",
                 "Имя для отображения в \"Опциях\"",
                 "Единицы для отображения в \"Опциях\"",
                 "Текущее значение или формула",
                 "Переменная атрибута",
                 "Тип атрибута",
                 "Данные для списка",
                 "Единицы размеров компонента"]
      defaults = ["",
                  "",
                  "использовать единицы модели",
                  "",
                  "текст",
                  "пользователи не видят атрибут.",
                  "",
                  "CENTIMETERS"]
      list = ["",
              "",
              "использовать единицы модели|целое число|десятичное число|процент|True/False|текст|дюймы|десятичные футы|миллиметры|сантиметры|метры|градусы|доллары|евро|йены|фунты(вес)|килограммы",
              "",
              "десятичное число|текст|дюймы|сантиметры",
              "пользователи не видят атрибут.|пользователи видят атрибут.|ввод в текстовом поле.|выбор из списка.",
              "",
              "INCHES|CENTIMETERS"]
      input = UI.inputbox(prompts, defaults, list, "Введите имена и значения атрибутов")
      selection.each do |entity|
        entity = selection[i]
        set_attributes(entity, input)
      end
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
