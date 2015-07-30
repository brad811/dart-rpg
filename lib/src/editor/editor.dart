library dart_rpg.editor;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/player.dart';
import 'package:dart_rpg/src/world.dart';

import 'map_editor.dart';
import 'object_editor.dart';

// TODO:
// - maybe make maps use numbers instead of names
//   - could simplify making references to them
//   - wouldn't be able to change so wouldn't ever have to update warps on name changes
//     - but what about warps that point to a map that no longer exists?
//       - probably delete
//       - but maybe point to self map

// TODO: apostraphes break everything

class Editor {
  static List<String> editorTabs = ["map_editor", "object_editor"];
  static bool highlightSpecialTiles = true;
  
  static Map<String, StreamSubscription> listeners = new Map<String, StreamSubscription>();
  
  static void init() {
    ObjectEditor.init();
    MapEditor.init(start);
  }
  
  static void start() {
    Main.player = new Player(0, 0, "");
    
    Main.world = new World(() {
      Main.world.loadGame(() {
        MapEditor.setUp();
        ObjectEditor.setUp();
        Editor.setUpTabs(editorTabs);
        
        Editor.update();
        
        Function resizeFunction = (Event e) {
          querySelector('#left_half').style.width = "${window.innerWidth - 562}px";
          querySelector('#left_half').style.height = "${window.innerHeight - 60}px";
          querySelector('#container').style.height = "${window.innerHeight - 10}px";
        };
        
        window.onResize.listen(resizeFunction);
        resizeFunction(null);
      });
    });
  }
  
  static void update() {
    MapEditor.update();
    ObjectEditor.update();
    
    Editor.export();
  }
  
  static void export() {
    Map<String, Map<String, Map<String, Object>>> exportJson = {};
    MapEditor.export(exportJson);
    ObjectEditor.export(exportJson);
    
    TextAreaElement textarea = querySelector("#export_json");
    textarea.value = JSON.encode(exportJson);
    
    TextAreaElement textarea2 = querySelector("#export_json_object_editor");
    textarea2.value = JSON.encode(exportJson);
  }
  
  static void setUpTabs(List<String> tabs) {
    Map<String, DivElement> tabDivs = {};
    Map<String, DivElement> tabHeaderDivs = {};
    
    for(String tab in tabs) {
      tabDivs[tab] = querySelector("#${tab}_tab");
      tabDivs[tab].style.display = "none";
      
      tabHeaderDivs[tab] = querySelector("#${tab}_tab_header");
      
      tabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in tabs) {
          tabDivs[tabb].style.display = "none";
          tabHeaderDivs[tabb].style.backgroundColor = "";
        }
        
        tabDivs[tab].style.display = "";
        tabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
      });
    }
    
    tabDivs[tabDivs.keys.first].style.display = "";
    tabHeaderDivs[tabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
  }
  
  static void setMapDeleteButtonListeners(Map<Object, Object> target, String targetName) {
    for(int i=0; i<target.keys.length; i++) {
      if(listeners["#delete_${targetName}_${i}"] != null)
        listeners["#delete_${targetName}_${i}"].cancel();
      
      listeners["#delete_${targetName}_${i}"] =
          querySelector("#delete_${targetName}_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
        if(confirm) {
          target.remove(target.keys.elementAt(i));
          Editor.update();
        }
      });
    }
  }
  
  static void setListDeleteButtonListeners(List<Object> target, String targetName) {
    for(int i=0; i<target.length; i++) {
      if(listeners["#delete_${targetName}_${i}"] != null)
        listeners["#delete_${targetName}_${i}"].cancel();
      
      listeners["#delete_${targetName}_${i}"] =
          querySelector("#delete_${targetName}_${i}").onClick.listen((MouseEvent e) {
        bool confirm = window.confirm('Are you sure you would like to delete this ${targetName}?');
        if(confirm) {
          target.removeAt(i);
          Editor.update();
        }
      });
    }
  }
  
  static void avoidNameCollision(Event e, String match, Map<String, Object> objects) {
    if(e.target is InputElement) {
      InputElement target = e.target;
      
      if(target.id.contains(match) && objects.keys.contains(target.value)) {
        // avoid name collisions
        int i = 0;
        for(; objects.keys.contains(target.value + "_${i}"); i++) {}
        target.value += "_${i}";
      }
    }
  }
  
  static void enforceValueFormat(Event e) {
    if(e.target is TextInputElement) {
      TextInputElement inputElement = e.target;
      
      if(inputElement.classes.contains("decimal")) {
        inputElement.value = inputElement.value.replaceAll(new RegExp(r'[^0-9\.]'), "");
      } else if(inputElement.classes.contains("number")) {
        inputElement.value = inputElement.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
    }
  }
  
  static void updateAndRetainValue(Event e) {
    if(e.target is TextInputElement) {
      // save the cursor location
      TextInputElement target = e.target;
      
      if(target.getAttribute("type") == "checkbox") {
        Editor.update();
        return;
      }
      
      TextInputElement inputElement = querySelector('#' + target.id);
      int position = inputElement.selectionStart;
      String valueBefore = inputElement.value;
      
      // update everything
      Editor.update();
      
      // restore the cursor position
      inputElement = querySelector('#' + target.id);
      inputElement.value = valueBefore;
      inputElement.focus();
      inputElement.setSelectionRange(position, position);
    } else if(e.target is TextAreaElement) {
      // save the cursor location
      TextAreaElement target = e.target;
      TextAreaElement inputElement = querySelector('#' + target.id);
      int position = inputElement.selectionStart;
      String valueBefore = inputElement.value;
      
      // update everything
      Editor.update();
      
      // restore the cursor position
      inputElement = querySelector('#' + target.id);
      inputElement.value = valueBefore;
      inputElement.focus();
      inputElement.setSelectionRange(position, position);
    } else {
      // update everything
      Editor.update();
    }
  }
  
  static void attachInputListeners(String prefix, List<String> attrs, Function onInputChange) {
    for(String attr in attrs) {
      String selector = "#${prefix}_${attr}";
      
      if(listeners[selector] != null)
        listeners[selector].cancel();
      
      HtmlElement element = querySelector(selector);
      String type = element.getAttribute("type");
      
      if(type == "text" || element is TextAreaElement) {
        listeners[selector] = element.onInput.listen(onInputChange);
      } else if(type == "checkbox" || element is SelectElement) {
        listeners[selector] = element.onChange.listen(onInputChange);
      } else {
        print("Error: unknown input type while attaching listener!");
      }
    }
  }
  
  static void attachButtonListener(String selector, Function onClick) {
    if(listeners[selector] != null)
      listeners[selector].cancel();
    
    listeners[selector] = querySelector(selector).onClick.listen(onClick);
  }
  
  static String getSelectInputStringValue(String divId) {
    try {
      return (querySelector(divId) as SelectElement).value;
    } catch(e) {
      return "";
    }
  }
  
  static int getSelectInputIntValue(String divId, int defaultValue) {
    try {
      return int.parse((querySelector(divId) as SelectElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
  
  static String getTextAreaStringValue(String divId) {
    try {
      return (querySelector(divId) as TextAreaElement).value;
    } catch(e) {
      return "";
    }
  }
  
  static String getTextInputStringValue(String divId) {
    return (querySelector(divId) as TextInputElement).value;
  }
  
  static int getTextInputIntValue(String divId, int defaultValue) {
    try {
      return int.parse((querySelector(divId) as TextInputElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
  
  static double getTextInputDoubleValue(String divId, double defaultValue) {
    try {
      return double.parse((querySelector(divId) as TextInputElement).value);
    } catch(e) {
      return defaultValue;
    }
  }
  
  static bool getCheckboxInputBoolValue(String divId) {
    try {
      return (querySelector(divId) as CheckboxInputElement).checked;
    } catch(e) {
      return false;
    }
  }
}