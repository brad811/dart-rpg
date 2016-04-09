library dart_rpg.switch_player_game_event;

import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class SwitchPlayerGameEvent implements GameEvent {
  static final String type = "switch_player";
  Function function, callback;
  
  String characterLabel;
  
  SwitchPlayerGameEvent(this.characterLabel, [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    Character character = World.characters[characterLabel];
    Main.player.characters = [character].toSet();
    callback();
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<JsObject> characterOptions = [];
    World.characters.forEach((String curCharacterLabel, Character character) {
      characterOptions.add(
        option({'value': curCharacterLabel}, curCharacterLabel)
      );
    });

    return table({}, tbody({},
      tr({},
        td({}, "Character")
      ),
      tr({},
        td({},
          select({
            'id': '${prefix}_character',
            'disabled': readOnly,
            'value': characterLabel,
            'onChange': onInputChange
          }, characterOptions)
        )
      )
    ));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    SwitchPlayerGameEvent switchPlayerGameEvent = new SwitchPlayerGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_character")
      );

    return switchPlayerGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["character"] = characterLabel;
    
    return gameEventJson;
  }
}