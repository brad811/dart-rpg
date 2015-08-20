library dart_rpg.object_editor;

import 'editor.dart';
import 'object_editor_attacks.dart';
import 'object_editor_battler_types.dart';
import 'object_editor_characters.dart';
import 'object_editor_game_events.dart';
import 'object_editor_items.dart';
import 'object_editor_player.dart';

class ObjectEditor {
  static List<String> objectEditorTabs = [
    "object_editor_attacks",
    "object_editor_battler_types",
    "object_editor_characters",
    "object_editor_items",
    "object_editor_player",
    "object_editor_game_event_chains"
  ];
  
  static void init() {
    
  }
  
  static void setUp() {
    Editor.setUpTabs(objectEditorTabs);
    
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