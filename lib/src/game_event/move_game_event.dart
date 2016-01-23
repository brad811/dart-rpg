library dart_rpg.move_game_event;

import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class MoveGameEvent implements GameEvent {
  static final String type = "move";
  Function function, callback;
  
  Character character;
  int direction;
  int distance;
  
  MoveGameEvent(this.direction, this.distance, [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
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
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange) {
    List<String> directions = ["Down", "Right", "Up", "Left"];
    List<JsObject> options = [];
    for(int dir=0; dir<directions.length; dir++) {
      options.add(
        option({'value': dir}, directions[dir])
      );
    }

    return table({}, tbody({}, [
      tr({}, [
        td({}, "Direction"),
        td({}, "Distance")
      ]),
      tr({}, [
        td({},
          select({'id': '${prefix}_direction', 'disabled': readOnly, 'value': direction}, options)
        ),
        td({},
          input({
            'type': 'text',
            'className': 'number',
            'id': '${prefix}_distance',
            'value': distance,
            'readOnly': readOnly
          })
        )
      ])
    ]));
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