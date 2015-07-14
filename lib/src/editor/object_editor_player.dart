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
    String playerHtml = "<table class='editor_table'>"+
      "  <tr>"+
      "    <td>Name</td><td>Battler Type</td><td>Level</td><td>Money</td>"+
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
      "    <td><input id='player_money' type='text' class='number' value='${Main.player.inventory.money}' /></td>"+
      "  </tr>";
    playerHtml += "</table>";
    querySelector("#player_container").setInnerHtml(playerHtml);
    
    List<String> ids = ["player_name", "player_battler_type", "player_level", "player_money"];
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
      if(target.id.contains("player_level") || target.id.contains("player_money")) {
        // enforce number format
        int selectionStart = (e.target as TextInputElement).selectionStart;
        target.value = target.value.replaceAll(new RegExp(r'[^0-9]'), "");
        (e.target as TextInputElement).selectionStart = selectionStart;
      }
    }
    
    Main.player.battler = new Battler(
      Editor.getTextInputStringValue('#player_name'),
      World.battlerTypes[battlerType],
      Editor.getTextInputIntValue('#player_level', 2),
      World.battlerTypes[battlerType].levelAttacks.values.toList()
    );
    
    Main.player.inventory.money = Editor.getTextInputIntValue("#player_money", 0);
    
    Editor.updateAndRetainValue(e);
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, Object> playerJson = {};
    playerJson["name"] = Main.player.battler.name;
    playerJson["battlerType"] = Main.player.battler.battlerType.name;
    playerJson["level"] = Main.player.battler.level;
    playerJson["money"] = Main.player.inventory.money;
    
    exportJson["player"] = playerJson;
  }
}