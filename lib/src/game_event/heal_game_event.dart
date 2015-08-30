library dart_rpg.heal_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

class HealGameEvent implements GameEvent {
  static final String type = "heal";
  Function function, callback;
  
  Character character;
  int amount;
  
  HealGameEvent(this.character, this.amount, [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    character.battler.curHealth += amount;
    
    if(character.battler.curHealth > character.battler.startingHealth)
      character.battler.curHealth = character.battler.startingHealth;
    
    // don't update the display health if in a battle, so it can be animated
    if(!Main.inBattle)
      character.battler.displayHealth = character.battler.curHealth;
    
    callback();
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions

  @override
  List<String> getAttributes() {
    return ["character", "amount"];
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
    html += "  <tr><td>Character</td><td>Amount</td></tr>";
    html += "  <tr>";
    
    // character
    html += "<td><select id='${prefix}_character' ${disabledString}>";
    
    html += "  <option value='____player'";
    if(character.label == "____player") {
      html += " selected";
    }
    html += ">Player</option>";
    
    World.characters.forEach((String charactrLabel, Character curCharacter) {
      html += "  <option value='${charactrLabel}'";
      if(character.label == charactrLabel) {
        html += " selected";
      }
      html += ">${charactrLabel}</option>";
    });
    
    html += "</select></td>";
    
    // amount
    html += "    <td><input type='text' class='number' id='${prefix}_amount' value='${amount}' ${readOnlyString} /></td>";
    
    html += "  </tr>";
    html += "</table>";
    
    return html;
  }
  
  static GameEvent buildGameEvent(String prefix) {
    Character character;
    String characterLabel = Editor.getSelectInputStringValue("#${prefix}_character");
    
    if(characterLabel == "____player") {
      character = Main.player;
    } else {
      character = World.characters[characterLabel];
    }
    
    HealGameEvent healGameEvent = new HealGameEvent(
        character, Editor.getTextInputIntValue("#${prefix}_amount", 0)
      );
    
    return healGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["character"] = character.label;
    gameEventJson["amount"] = amount;
    
    return gameEventJson;
  }
}