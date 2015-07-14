library dart_rpg.object_editor;

import 'dart:html';

import 'object_editor_attacks.dart';
import 'object_editor_battler_types.dart';
import 'object_editor_characters.dart';
import 'object_editor_game_events.dart';
import 'object_editor_items.dart';
import 'object_editor_player.dart';

class ObjectEditor {
  static List<String> objectEditorTabs = ["attacks", "battler_types", "characters", "items", "player", "game_event_chains"];
  static Map<String, DivElement> objectEditorTabDivs = {};
  static Map<String, DivElement> objectEditorTabHeaderDivs = {};
  
  static void init() {
    
  }
  
  static void setUp() {
    for(String tab in objectEditorTabs) {
      objectEditorTabDivs[tab] = querySelector("#object_editor_${tab}_tab");
      objectEditorTabDivs[tab].classes.add("hidden");
      
      objectEditorTabHeaderDivs[tab] = querySelector("#object_editor_${tab}_tab_header");
      
      objectEditorTabHeaderDivs[tab].onClick.listen((MouseEvent e) {
        for(String tabb in objectEditorTabs) {
          objectEditorTabDivs[tabb].classes.add("hidden");
          objectEditorTabHeaderDivs[tabb].style.backgroundColor = "";
          
          // hide any advanced sections in the right half
          if(querySelector("#${tabb}_advanced") != null) {
            querySelector("#${tabb}_advanced").classes.add("hidden");
          }
        }
        
        objectEditorTabDivs[tab].classes.remove("hidden");
        objectEditorTabHeaderDivs[tab].style.backgroundColor = "#eeeeee";
        
        // un-select any character rows and redraw the character tab
        ObjectEditorCharacters.selected = null;
        ObjectEditorCharacters.update();
      });
    }
    
    objectEditorTabDivs[objectEditorTabDivs.keys.first].classes.remove("hidden");
    objectEditorTabHeaderDivs[objectEditorTabHeaderDivs.keys.first].style.backgroundColor = "#eeeeee";
    
    ObjectEditorAttacks.setUp();
    ObjectEditorBattlerTypes.setUp();
    ObjectEditorCharacters.setUp();
    ObjectEditorItems.setUp();
    ObjectEditorPlayer.setUp();
    ObjectEditorGameEvents.setUp();
  }
  
  static void update() {
    ObjectEditorAttacks.update();
    ObjectEditorBattlerTypes.update();
    ObjectEditorCharacters.update();
    ObjectEditorItems.update();
    ObjectEditorPlayer.update();
    ObjectEditorGameEvents.update();
  }
  
  static void export(Map<String, Map<String, Map<String, Object>>> exportJson) {
    ObjectEditorAttacks.export(exportJson);
    ObjectEditorBattlerTypes.export(exportJson);
    ObjectEditorCharacters.export(exportJson);
    ObjectEditorItems.export(exportJson);
    ObjectEditorPlayer.export(exportJson);
    ObjectEditorGameEvents.export(exportJson);
  }
}