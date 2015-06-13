library dart_rpg.object_editor_player;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/battler_type.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

class ObjectEditorPlayer {
  static Map<String, StreamSubscription> listeners = {};
  
  static void setUp() {
  }
  
  static void update() {
    // TODO: inventory
    // TODO: everything else for this tab
    String playerHtml = "<table>"+
      "  <tr>"+
      "    <td>Name</td><td>Battler Type</td><td>Level</td><td>X</td><td>Y</td>"+
      "  </tr>"+
      "  <tr>"+
      "    <td><input type='text' value='${Main.player.battler.name}' /></td>"+
      "    <td>";
      
    playerHtml += "<select id='object_editor_player_battler_type'>";
    World.battlerTypes.forEach((String name, BattlerType battlerType) {
      playerHtml += "<option value='${battlerType.name}'";
      if(Main.player.battler.name == name) {
        playerHtml += " selected";
      }
      
      playerHtml += ">${battlerType.name}</option>";
    });
    playerHtml += "</select>";
      
    playerHtml +=
      "    </td>"+
      "    <td><input type='text' class='number' value='${Main.player.battler.level}' /></td>"+
      "  </tr>";
    playerHtml += "</table>";
    querySelector("#player_container").innerHtml = playerHtml;
  }
  
  static void export(Map<String, Object> exportJson) {
    Map<String, String> playerJson = {};
    playerJson["x"] = Main.player.mapX.toString();
    playerJson["y"] = Main.player.mapY.toString();
    
    exportJson["player"] = playerJson;
  }
}