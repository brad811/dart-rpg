library dart_rpg.move_game_event;

import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MoveGameEvent implements GameEvent {
  static final String type = "move";
  Function function, callback;
  
  String characterLabel;
  int direction;
  int distance;
  
  MoveGameEvent(this.characterLabel, this.direction, this.distance, [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    Character character;
    
    if(characterLabel == "____player") {
      character = Main.player.character;
    } else {
      character = World.characters[characterLabel];
    }
    
    int traveled = 0;
    
    Main.player.inputEnabled = false;
    chainCharacterMovement(character, traveled);
  }
  
  void chainCharacterMovement(Character character, int traveled) {
    if(traveled >= distance) {
      Main.player.inputEnabled = true;
      callback();
    } else {
      character.move(direction);
      character.motionCallback = () {
        chainCharacterMovement(character, traveled + 1);
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
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<JsObject> characterOptions = [];
    characterOptions.add(
      option({'value': '____player'}, "Player")
    );
    World.characters.forEach((String curCharacterLabel, Character character) {
      characterOptions.add(
        option({'value': curCharacterLabel}, curCharacterLabel)
      );
    });

    List<String> directions = ["Down", "Right", "Up", "Left"];
    List<JsObject> direction_options = [];
    for(int dir=0; dir<directions.length; dir++) {
      direction_options.add(
        option({'value': dir}, directions[dir])
      );
    }

    return table({}, tbody({},
      tr({},
        td({}, "Character"),
        td({}, "Direction"),
        td({}, "Distance")
      ),
      tr({},
        td({},
          select({
            'id': '${prefix}_character',
            'disabled': readOnly,
            'value': characterLabel,
            'onChange': onInputChange
          }, characterOptions)
        ),
        td({},
          select({
            'id': '${prefix}_direction',
            'disabled': readOnly,
            'value': direction,
            'onChange': onInputChange
          }, direction_options)
        ),
        td({},
          input({
            'id': '${prefix}_distance',
            'type': 'text',
            'className': 'number',
            'value': distance,
            'readOnly': readOnly,
            'onChange': onInputChange
          })
        )
      )
    ));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    MoveGameEvent moveGameEvent = new MoveGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_character"),
        Editor.getSelectInputIntValue("#${prefix}_direction", Character.DOWN),
        Editor.getTextInputIntValue("#${prefix}_distance", 1)
      );
    
    if(moveGameEvent.characterLabel == "") {
      moveGameEvent.characterLabel = "____player";
    }

    return moveGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["character"] = characterLabel;
    gameEventJson["direction"] = direction;
    gameEventJson["distance"] = distance;
    
    return gameEventJson;
  }
}