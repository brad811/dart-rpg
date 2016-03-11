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
    
    if(characterLabel == "____player" || characterLabel == Main.player.character.label) {
      character = Main.player.character;
      Main.world.curMap = newMap;
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
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
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
    
    List<JsObject> layerOptions = [];
    for(int curLayer=0; curLayer<World.layers.length; curLayer++) {
      layerOptions.add(
        option({'value': curLayer}, World.layers[curLayer])
      );
    }

    List<String> directions = ["Down", "Right", "Up", "Left"];
    List<JsObject> directionOptions = [];
    for(int curDirection=0; curDirection<directions.length; curDirection++) {
      directionOptions.add(
        option({'value': curDirection}, directions[curDirection])
      );
    }

    return div({},
      table({}, tbody({},
        tr({},
          td({}, "Character"),
          td({}, "New Map")
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
              'id': '${prefix}_new_map',
              'disabled': readOnly,
              'value': newMap,
              'onChange': onInputChange
            }, mapOptions)
          )
        )
      )),
      br({}),
      table({}, tbody({},
        tr({},
          td({}, "X"),
          td({}, "Y"),
          td({}, "Layer"),
          td({}, "Direction")
        ),
        tr({},
          td({},
            Editor.generateInput({
              'id': '${prefix}_x',
              'type': 'text',
              'className': 'number',
              'value': x,
              'readOnly': readOnly,
              'onChange': onInputChange
            })
          ),
          td({},
            Editor.generateInput({
              'id': '${prefix}_y',
              'type': 'text',
              'className': 'number',
              'value': y,
              'readOnly': readOnly,
              'onChange': onInputChange
            })
          ),
          td({},
            select({
              'id': '${prefix}_layer',
              'disabled': readOnly,
              'value': layer,
              'onChange': onInputChange
            }, layerOptions)
          ),
          td({},
            select({
              'id': '${prefix}_direction',
              'disabled': readOnly,
              'value': direction,
              'onChange': onInputChange
            }, directionOptions)
          )
        )
      ))
    );
  }
  
  static GameEvent buildGameEvent(String prefix) {
    WarpGameEvent warpGameEvent = new WarpGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_character"),
        Editor.getSelectInputStringValue("#${prefix}_new_map"),
        Editor.getTextInputIntValue("#${prefix}_x", 0),
        Editor.getTextInputIntValue("#${prefix}_y", 0),
        Editor.getSelectInputIntValue("#${prefix}_layer", 0),
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