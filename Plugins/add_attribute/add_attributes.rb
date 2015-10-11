# Copyright 2014, Igor Sepelev aka goga63
# All Rights Reserved
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------------
# License: GPL V.3
# Author: Igor Sepelev aka goga63
# Organization:
# Name: unique_colors_for_layers.rb
# Version: 1.0
# Description: Plugin makes unique all colors of layers in model
# Usage: see README
# History:
# 1.0 Initial release
# 1.1 11-October-2014
#  - add english version of dialogs and toolbar icon by Yurij Kulchevich
#------------------------------------------------------------------------------

require 'sketchup.rb'

def set_attributes(entity ,input)    # метод записи атрибутоа
  massiv = ["десятичное число","текст","дюймы","сантиметры"]
  attributes_formulaunits =input[4]
  attributes_formulaunits =massiv.index(attributes_formulaunits)
  massiv = ["FLOAT","STRING","INCHES","CENTIMETERS"]
  attributes_formulaunits =massiv[attributes_formulaunits]
  entity.set_attribute'dynamic_attributes',"_"+input[0]+"_formulaunits",attributes_formulaunits.to_s
  massiv =["использовать единицы модели","целое число","десятичное число","процент","True/False","текст","дюймы","десятичные футы","миллиметры","сантиметры","метры","градусы","доллары","евро","йены","фунты(вес)","килограммы"]
  attributes_units =input[2]
  attributes_units =massiv.index(attributes_units)
  massiv =["DEFAULT","INTEGER","FLOAT","PERCENT","BOOLEAN","STRING","INCHES","FEET","MILLIMETERS","CENTIMETERS","METERS","DEGREES","DOLLARS","EUROS","YEN","POUNDS","KILOGRAMS"]
  attributes_units =massiv[attributes_units]
  entity.set_attribute'dynamic_attributes',"_" +input[0]+"_units",attributes_units.to_s
  entity.set_attribute'dynamic_attributes','_lengthunits',input[7]
  entity.set_attribute'dynamic_attributes',"_" +input[0]+"_label",input[0]     # имя атрибута
  entity.set_attribute'dynamic_attributes',("_"+input[0]+"_formlabel"),input[1]             # Имя для показа в опциях
  data_attribute=input[3]
  if (input[2]=="миллиметры")
    # текущее значение (введенное  input[3])
    entity.set_attribute'dynamic_attributes',input[0],(data_attribute.to_f*0.0393700787401575)
    else
      if (input[2]=="сантиметры")
        # текущее значение (введенное  input[3])
      entity.set_attribute'dynamic_attributes',input[0],(data_attribute.to_f*0.393700787401575)
      else
        if (input[2]=="метры")
          # текущее значение (введенное  input[3])
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
  entity.set_attribute'dynamic_attributes',"_" +input[0]+"_access",attributes_access.to_s
  if input[6] != nil
    entity.set_attribute'dynamic_attributes',"_" + input[0] + "_options",input[6]
  end
end #set_attributes

def isSimpleEntity_attr(entity)

  if ((entity.typename =="ComponentInstance"))
    return false
  else
    return true
  end
end

def recursive_count_attr(entity,input)
  if ((entity.typename =="Face") || (entity.typename =="Edge"))
    simple =0
    complex =0
    if (entity.typename =="ComponentInstance")
      for i in 0..entity.definition.entities.count - 1
        if (isSimpleEntity_attr(entity.definition.entities[i]))
          simple =simple + 1
        else
          complex =complex + 1
          recursive_count_attr(entity.definition.entities[i])
        end
      end
    end
    if ((simple>0)&&(complex==0))
      set_attributes(entity,input) # вызов метода записи атрибутоа
    end
  end
end


def search_of_components
  model = Sketchup.active_model
  selection = model.selection
  if selection.count == 0
    UI.messagebox("Компоненты не выбраны")
    return nil
  else
    prompts =["Назначить"]
    defaults =["пользовательские атрибуты"]
    list =["пользовательские атрибуты|предустановленные атрибуты"]
    input =UI.inputbox prompts, defaults, list,"Выберете атрибуты для установки"
    if input[0] =="пользовательские атрибуты"
      prompts =["Имя атрибута","Имя для отображения в \"Опциях\"","Единицы для отображения в \"Опциях\"","Текущее значение или формула","Переменная атрибута","Тип атрибута","Данные для списка","Единицы размеров компонента"]
      defaults =["","","использовать единицы модели","","текст","пользователи не видят атрибут.","","CENTIMETERS"]
      list =["","","использовать единицы модели|целое число|десятичное число|процент|True/False|текст|дюймы|десятичные футы|миллиметры|сантиметры|метры|градусы|доллары|евро|йены|фунты(вес)|килограммы","","десятичное число|текст|дюймы|сантиметры","пользователи не видят атрибут.|пользователи видят атрибут.|ввод в текстовом поле.|выбор из списка.","","INCHES|CENTIMETERS"]
      input =UI.inputbox prompts,defaults,list,"Введите имена и значения атрибутов"
    else
      # сначала предустановленные атрибуты по списку
      prompts =["Имя атрибута","Имя для отображения в \"Опциях\"","Единицы для отображения в \"Опциях\"","Текущее значение или формула","Переменная атрибута","Тип атрибута","Данные для списка"]
      defaults =["","","использовать единицы модели","","текст","пользователи не видят атрибут.",""]
      list =["","","использовать единицы модели|целое число|десятичное число|процент|True/False|текст|дюймы|десятичные футы|миллиметры|сантиметры|метры|градусы|доллары|евро|йены|фунты(вес)|килограммы","","десятичное число|текст|дюймы|сантиметры","пользователи не видят атрибут.|пользователи видят атрибут.|ввод в текстовом поле.|выбор из списка.",""]
      input =UI.inputbox prompts,defaults,list,"Введите имена и значения атрибутов"
    end
  end
  for i in 0..selection.count-1
    entity =selection[i]
    set_attributes(entity,input)
  end
end

# get the SketchUp plugins menu
UI.menu("Plugins").add_item("Установка Атрибутов"){search_of_components}

file_loaded("set_attributes.rb")
