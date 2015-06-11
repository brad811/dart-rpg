library dart_rpg.object_editor;

import 'dart:html';

import 'object_editor_attacks.dart';
import 'object_editor_battler_types.dart';
import 'object_editor_player.dart';

class ObjectEditor {
  static List<String> objectEditorTabs = ["attacks", "battler_types", "characters", "items", "player"];
  static Map<String, DivElement> objectEditorTabDivs = {};
  static Map<String, DivElement> objectEditorTabHeaderDivs = {};
  
  static void init() {
    
  }
  
  static void setUp() {
    for(String tab in objectEditorTabs) {
      objectEditorTabDivs[tab] = querySelector("#object_editor_${tab}_tab");
      objectEditorTabDivs[tab].style.display = "none";
      
      objectEditorTabHeaderDivs[tab] = querySelector("#object_editor_${tab}_tab_header");
      
      objectEditorTabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in objectEditorTabs) {
          objectEditorTabDivs[tabb].style.display = "none";
          objectEditorTabHeaderDivs[tabb].style.backgroundColor = "";
        }
        
        objectEditorTabDivs[tab].style.display = "block";
        objectEditorTabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
      });
    }
    
    objectEditorTabDivs[objectEditorTabDivs.keys.first].style.display = "block";
    objectEditorTabHeaderDivs[objectEditorTabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
    
    ObjectEditorAttacks.setUp();
    ObjectEditorBattlerTypes.setUp();
    /*
    ObjectEditorCharacters.setUp();
    ObjectEditorItems.setUp();
    */
    ObjectEditorPlayer.setUp();
  }
  
  static void update() {
    ObjectEditorAttacks.update();
    ObjectEditorBattlerTypes.update();
    /*
    ObjectEditorCharacters.update();
    ObjectEditorItems.update();
    */
    ObjectEditorPlayer.update();
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    ObjectEditorAttacks.export(exportJson);
    ObjectEditorBattlerTypes.export(exportJson);
    /*
    ObjectEditorCharacters.export(exportJson);
    ObjectEditorItems.export(exportJson);
    */
    ObjectEditorPlayer.export(exportJson);
  }
}