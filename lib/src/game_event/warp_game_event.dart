library dart_rpg.warp_game_event;

import 'dart:js';

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

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
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange) {
    // TODO: perhaps add generators for these in base editor
    
    List<JsObject> characterOptions = [];

    characterOptions.add(
      option({'value': '____player'}, "Player")
    );

    World.characters.forEach((String curCharacterLabel, Character character) {
      characterOptions.add(
        option({'value': curCharacterLabel}, curCharacterLabel)
      );
    });
    
    List<JsObject> mapOptions = [];
    Main.world.maps.keys.forEach((String key) {
      mapOptions.add(
        option({'value': key}, key)
      );
    });
    
    List<String> layers = ["Ground", "Below", "Player", "Above"];
    List<JsObject> layerOptions = [];
    for(int curLayer=0; curLayer<layers.length; curLayer++) {
      layerOptions.add(
        option({'value': curLayer}, layers[curLayer])
      );
    }

    List<String> directions = ["Down", "Right", "Up", "Left"];
    List<JsObject> directionOptions = [];
    for(int curDirection=0; curDirection<directions.length; curDirection++) {
      directionOptions.add(
        option({'value': curDirection}, directions[curDirection])
      );
    }

    return div({}, [
      table({}, tbody({}, [
        tr({}, [
          td({}, "Character"),
          td({}, "New Map")
        ]),
        tr({}, [
          td({},
            select({'id': '${prefix}_character', 'disabled': readOnly, 'value': characterLabel}, characterOptions)
          ),
          td({},
            select({'id': '${prefix}_new_map', 'disabled': readOnly, 'value': newMap}, mapOptions)
          )
        ])
      ])),
      br({}),
      table({}, tbody({}, [
        tr({}, [
          td({}, "X"),
          td({}, "Y"),
          td({}, "Layer"),
          td({}, "Direction")
        ]),
        tr({}, [
          td({},
            input({'type': 'text', 'className': 'number', 'id': '${prefix}_x', 'value': x, 'readOnly': readOnly})
          ),
          td({},
            input({'type': 'text', 'className': 'number', 'id': '${prefix}_y', 'value': y, 'readOnly': readOnly})
          ),
          td({},
            select({'id': '${prefix}_layer', 'disabled': readOnly, 'value': layer}, layerOptions)
          ),
          td({},
            select({'id': '${prefix}_direction', 'disabled': readOnly, 'value': direction}, directionOptions)
          )
        ])
      ]))
    ]);
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