library dart_rpg.heal_game_event;

import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class HealGameEvent implements GameEvent {
  static final String type = "heal";
  Function function, callback;
  
  Character character;
  int amount;
  
  String characterLabel = "";
  
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
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<JsObject> options = [
      option({'value': '____player'}, "Current Player")
    ];
    
    World.characters.forEach((String characterLabel, Character curCharacter) {
      options.add(
        option({'value': characterLabel}, characterLabel)
      );
    });
    
    return table({}, tbody({},
      tr({},
        td({},
          select({
            'id': '${prefix}_character',
            'disabled': readOnly,
            'value': characterLabel,
            'onChange': onInputChange
          }, options)
        ),
        td({},
          Editor.generateInput({
            'id': '${prefix}_amount',
            'type': 'text',
            'className': 'number',
            'value': amount,
            'readOnly': readOnly,
            'onChange': onInputChange
          })
        )
      )
    ));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    Character character;
    String characterLabel = Editor.getSelectInputStringValue("#${prefix}_character");
    
    if(characterLabel == "____player") {
      character = Main.player.character;
    } else {
      character = World.characters[characterLabel];
    }
    
    HealGameEvent healGameEvent = new HealGameEvent(
      character, Editor.getTextInputIntValue("#${prefix}_amount", 0)
    );
    
    healGameEvent.characterLabel = characterLabel;
    
    return healGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["character"] = this.characterLabel;
    gameEventJson["amount"] = amount;
    
    return gameEventJson;
  }
}