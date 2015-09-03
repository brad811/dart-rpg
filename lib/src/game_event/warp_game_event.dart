library dart_rpg.warp_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class WarpGameEvent extends GameEvent {
  static final String type = "warp";
  Function callback;
  
  String characterLabel;
  String newMap;
  int x, y, layer, direction;
  
  WarpGameEvent(this.characterLabel,
    this.newMap, this.x, this.y, this.layer, this.direction,
    [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    Character character;
    
    if(characterLabel == "____player") {
      character = Main.player.character;
    } else {
      character = World.characters[characterLabel];
    }
      
    character.warp(newMap, x, y, layer, direction);
    callback();
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  List<String> getAttributes() {
    return ["character", "new_map", "x", "y", "layer", "direction"];
  }
  
  @override
  String getType() => type;
  
  @override
  String buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange) {
    String html = "";
    
    String disabledString = "";
    String readOnlyString = "";
    if(readOnly) {
      disabledString = "disabled='disabled' ";
      readOnlyString = "readonly";
    }
    
    html += "<table>";
    html += "  <tr><td>Character</td><td>New Map</td></tr>";
    html += "  <tr>";
    
    // TODO: perhaps add generators for these in base editor
    
    // character
    html += "<td><select id='${prefix}_character' ${disabledString}>";
    
    html += "  <option value='____player'";
    if(characterLabel == "____player") {
      html += " selected";
    }
    html += ">Player</option>";
    
    World.characters.forEach((String curCharacterLabel, Character character) {
      html += "  <option value='${curCharacterLabel}'";
      if(characterLabel == curCharacterLabel) {
        html += " selected";
      }
      html += ">${curCharacterLabel}</option>";
    });
    
    html += "</select></td>";
    
    // new map selector
    html += "<td><select id='${prefix}_new_map' ${disabledString}>";
    Main.world.maps.keys.forEach((String key) {
      html += "<option value='${key}'";
      if(newMap == key) {
        html += " selected";
      }
      
      html += ">${key}</option>";
    });
    
    html += "</tr></table> <br /> <table><tr><td>X</td><td>Y</td><td>Layer</td><td>Direction</td></tr><tr>";
    
    // x
    html += "<td><input type='text' class='number' id='${prefix}_x' value='${x}' ${readOnlyString} /></td>";
    
    // y
    html += "<td><input type='text' class='number' id='${prefix}_y' value='${y}' ${readOnlyString} /></td>";
    
    // layer
    html += "<td><select id='${prefix}_layer' ${disabledString}>";
    List<String> layers = ["Ground", "Below", "Player", "Above"];
    for(int curLayer=0; curLayer<layers.length; curLayer++) {
      html += "<option value='${curLayer}'";
      if(layer == curLayer) {
        html += " selected";
      }
      
      html += ">${layers[curLayer]}</option>";
    }
    html += "</select></td>";
    
    // direction
    html += "<td><select id='${prefix}_direction' ${disabledString}>";
    List<String> directions = ["Down", "Right", "Up", "Left"];
    for(int curDirection=0; curDirection<directions.length; curDirection++) {
      html += "<option value='${curDirection}'";
      if(direction == curDirection) {
        html += " selected";
      }
      
      html += ">${directions[curDirection]}</option>";
    }
    html += "</select></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    WarpGameEvent warpGameEvent = new WarpGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_character"),
        Editor.getSelectInputStringValue("#${prefix}_new_map"),
        Editor.getTextInputIntValue("#${prefix}_x", 0),
        Editor.getTextInputIntValue("#${prefix}_y", 0),
        Editor.getSelectInputIntValue("#${prefix}_layer", World.LAYER_BELOW),
        Editor.getSelectInputIntValue("#${prefix}_direction", Character.DOWN)
      );
    
    return warpGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["character"] = characterLabel;
    gameEventJson["newMap"] = newMap;
    gameEventJson["x"] = x;
    gameEventJson["y"] = y;
    gameEventJson["layer"] = layer;
    gameEventJson["direction"] = direction;
    
    return gameEventJson;
  }
}