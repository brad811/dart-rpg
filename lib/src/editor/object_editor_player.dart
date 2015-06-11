library dart_rpg.object_editor_player;

import 'dart:async';
import 'dart:html';

import 'package:dart_rpg/src/main.dart';

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
      "    <td><input type='text' /></td>"+
      "    <td><select><option>TODO</option></select></td>"+
      "    <td><input type='text' class='number' /></td>"+
      "    <td><input type='text' class='number' /></td>"+
      "    <td><input type='text' class='number' /></td>"+
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