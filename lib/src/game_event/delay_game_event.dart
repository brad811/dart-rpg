library dart_rpg.delay_game_event;

import 'dart:async';
import 'dart:js';

import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class DelayGameEvent implements GameEvent {
  static final String type = "delay";
  Function function, callback;
  
  int milliseconds;
  
  DelayGameEvent(this.milliseconds, [this.callback]);
  
  void trigger(Interactable interactable, [Function function]) {
    Main.player.inputEnabled = false;
    Future future = new Future.delayed(new Duration(milliseconds: milliseconds), () {});
    
    future.then((_) {
      Main.player.inputEnabled = true;
      callback();
    });
  }
  
  @override
  void handleInput(List<InputCode> inputCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    return table({}, tbody({},
      tr({},
        td({}, "Milliseconds")
      ),
      tr({},
        td({},
          Editor.generateInput({
            'type': 'text',
            'className': 'number',
            'id': '${prefix}_milliseconds',
            'value': milliseconds,
            'readOnly': readOnly ? 'disabled' : '',
            'onChange': onInputChange
          })
        )
      )
    ));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    DelayGameEvent delayGameEvent = new DelayGameEvent(
        Editor.getTextInputIntValue("#${prefix}_milliseconds", 100)
      );
    
    return delayGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["milliseconds"] = milliseconds;
    
    return gameEventJson;
  }
}