library dart_rpg.chain_game_event;

import "dart:js";

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class ChainGameEvent implements GameEvent {
  static final String type = "chain";
  Function function, callback;
  
  String gameEventChain = "";
  bool makeDefault = false;
  
  ChainGameEvent(this.gameEventChain, this.makeDefault, [this.callback]);
  
  void trigger(Interactable interactable, [Function function]) {
    List<GameEvent> gameEvents = World.gameEventChains[gameEventChain];
    if(gameEvents != null && gameEvents.length > 0) {
      if(makeDefault) {
        interactable.setGameEventChain(gameEventChain, 0);
      }
      
      Main.focusObject = null;
      Interactable.chainGameEvents(interactable, gameEvents).trigger(interactable);
    } else {
      callback();
    }
  }
  
  @override
  void handleKeys(List<int> keyCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  List<String> getAttributes() {
    return ["game_event_chain", "make_default"];
  }
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<JsObject> tableRows = [];

    tableRows.add(
      tr({},
        td({}, "Game Event Chain"),
        td({}, "Make Default")
      )
    );

    List<JsObject> options = [];

    World.gameEventChains.keys.forEach((String key) {
      options.add(
        option({'value': key}, key)
      );
    });

    tableRows.add(
      tr({},
        td({},
          select(
            {
              'id': '${prefix}_game_event_chain',
              'disabled': readOnly,
              'value': gameEventChain,
              'onChange': onInputChange
            },
            options
          )
        ),
        td({},
          Editor.generateInput({
            'id': '${prefix}_make_default',
            'type': 'checkbox',
            'checked': makeDefault,
            'onChange': onInputChange
          })
        )
      )
    );
    
    return table({}, tbody({}, tableRows));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    ChainGameEvent chainGameEvent = new ChainGameEvent(
        Editor.getSelectInputStringValue("#${prefix}_game_event_chain"),
        Editor.getCheckboxInputBoolValue("#${prefix}_make_default")
      );
    
    return chainGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["gameEventChain"] = gameEventChain;
    gameEventJson["makeDefault"] = makeDefault;
    
    return gameEventJson;
  }
}