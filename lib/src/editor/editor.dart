library dart_rpg.editor;

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

// TODO: add delete buttons to maps

class Editor {
  static List<String> editorTabs = ["map_editor", "object_editor"];
  static Map<String, DivElement> editorTabDivs = {};
  static Map<String, DivElement> editorTabHeaderDivs = {};
  
  static void init() {
    ObjectEditor.init();
    MapEditor.init(start);
  }
  
  static void start() {
    Main.player = new Player(0, 0);
    
    Main.world = new World(() {
      Main.world.loadMaps(() {
        MapEditor.setUp();
        ObjectEditor.setUp();
        Editor.setUpTabs();
        
        Editor.update();
        
        Function resizeFunction = (Event e) {
          querySelector('#left_half').style.width = "${window.innerWidth - 580}px";
          querySelector('#left_half').style.height = "${window.innerHeight - 60}px";
          querySelector('#container').style.height = "${window.innerHeight - 30}px";
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
  }
  
  static void setUpTabs() {
    for(String tab in editorTabs) {
      editorTabDivs[tab] = querySelector("#${tab}_tab");
      editorTabDivs[tab].style.display = "none";
      
      editorTabHeaderDivs[tab] = querySelector("#${tab}_tab_header");
      
      editorTabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in editorTabs) {
          editorTabDivs[tabb].style.display = "none";
          editorTabHeaderDivs[tabb].style.backgroundColor = "";
        }
        
        editorTabDivs[tab].style.display = "";
        editorTabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
      });
    }
    
    editorTabDivs[editorTabDivs.keys.first].style.display = "";
    editorTabHeaderDivs[editorTabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
  }
}