library dart_rpg.object_editor_player;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class ObjectEditorPlayer {
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
  }
  
  static void update() {
    // TODO: inventory
    // TODO: everything else for this tab
    String playerHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Name</td><td>Battler Type</td><td>Level</td>"+
      "  </tr>"+
      "  <tr>"+
      "    <td><input id='player_name' type='text' value='${Main.player.battler.name}' /></td>"+
      "    <td>";
      
    playerHtml += "<select id='player_battler_type'>";
    World.battlerTypes.forEach((String name, BattlerType battlerType) {
      playerHtml += "<option value='${battlerType.name}'";
      if(Main.player.battler.battlerType.name == name) {
        playerHtml += " selected";
      }
      
      playerHtml += ">${battlerType.name}</option>";
    });
    playerHtml += "</select>";
      
    playerHtml +=
      "    </td>"+
      "    <td><input id='player_level' type='text' class='number' value='${Main.player.battler.level}' /></td>"+
      "  </tr>";
    playerHtml += "</table>";
    querySelector("#player_container").innerHtml = playerHtml;
    
    List<String> ids = ["player_name", "player_battler_type", "player_level"];
    ids.forEach((String id) {
      if(listeners["#${id}"] != null)
        listeners["#${id}"].cancel();
      
      listeners["#${id}"] = querySelector('#${id}').onInput.listen(onInputChange);
    });
  }
  
  static void onInputChange(Event e) {
    String battlerType = (querySelector('#player_battler_type') as SelectElement).value;
    
    if(e.target is TextInputElement) {
      TextInputElement target = e.target as TextInputElement;
      if(target.id.contains("player_level")) {
        // enforce number format
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
      }
    }
    
    Main.player.battler = new Battler(
      (querySelector('#player_name') as TextInputElement).value,
      World.battlerTypes[battlerType],
      int.parse((querySelector('#player_level') as TextInputElement).value),
      World.battlerTypes[battlerType].levelAttacks.values.toList()
    );
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, String> playerJson = {};
    playerJson["name"] = Main.player.battler.name;
    playerJson["battlerType"] = Main.player.battler.battlerType.name;
    playerJson["level"] = Main.player.battler.level.toString();
    
    exportJson["player"] = playerJson;
  }
}