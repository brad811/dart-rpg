library dart_rpg.move_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class MoveGameEvent implements GameEvent {
  static final String type = "move";
  Function function, callback;
  
  Character character;
  int direction;
  int distance;
  
  MoveGameEvent(this.direction, this.distance, [this.callback]);
  
  @override
  void trigger(InteractableInterface interactable, [Function function]) {
    character = interactable as Character;
    
    int traveled = 0;
    
    Main.player.inputEnabled = false;
    chainCharacterMovement(traveled);
  }
  
  void chainCharacterMovement(int traveled) {
    if(traveled >= distance) {
      Main.player.inputEnabled = true;
      callback();
    } else {
      character.move(direction);
      character.motionCallback = () {
        chainCharacterMovement(traveled + 1);
      };
    }
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  List<String> getAttributes() {
    return ["direction", "distance"];
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
    html += "  <tr><td>Direction</td><td>Distance</td></tr>";
    html += "  <tr>";
    
    // direction
    html += "<td><select id='${prefix}_direction' ${disabledString}>";
    List<String> directions = ["Down", "Right", "Up", "Left"];
    for(int dir=0; dir<directions.length; dir++) {
      html += "<option value='${dir}'";
      if(direction == dir) {
        html += " selected";
      }
      
      html += ">${directions[dir]}</option>";
    }
    html += "</select></td>";
    
    // distance
    html += "    <td><input type='text' class='number' id='${prefix}_distance' value='${distance}' ${readOnlyString} /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    MoveGameEvent moveGameEvent = new MoveGameEvent(
        Editor.getSelectInputIntValue("#${prefix}_direction", Character.DOWN),
        Editor.getTextInputIntValue("#${prefix}_distance", 1)
      );
    
    return moveGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["direction"] = direction;
    gameEventJson["distance"] = distance;
    
    return gameEventJson;
  }
}