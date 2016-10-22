library dart_rpg.fade_game_event;

import 'dart:js';

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/input.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/delayed_game_event.dart';

import 'package:dart_rpg/src/editor/editor.dart';

import 'package:react/react.dart';

class FadeGameEvent implements GameEvent {
  static final String type = "fade";
  Function function, callback;
  
  int fadeType = 0;
  
  static final int
    FADE_NORMAL_TO_WHITE = 1,
    FADE_WHITE_TO_NORMAL = 2,
    FADE_NORMAL_TO_BLACK = 3,
    FADE_BLACK_TO_NORMAL = 4;
  
  List<List<int>> fades = [
    [Gui.FADE_WHITE_LOW, Gui.FADE_WHITE_MED, Gui.FADE_WHITE_FULL],
    [Gui.FADE_WHITE_MED, Gui.FADE_WHITE_LOW, Gui.FADE_NORMAL],
    [Gui.FADE_BLACK_LOW, Gui.FADE_BLACK_MED, Gui.FADE_BLACK_FULL],
    [Gui.FADE_BLACK_MED, Gui.FADE_BLACK_LOW, Gui.FADE_NORMAL]
  ];
  
  FadeGameEvent(this.fadeType, [this.callback]);
  
  @override
  void trigger(Interactable interactable, [Function function]) {
    Main.player.inputEnabled = false;
    Main.timeScale = 0.0;
    
    List<int> fadeLevels = fades[fadeType];
    
    DelayedGameEvent.executeDelayedEvents([
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = fadeLevels[0];
      }),
      
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = fadeLevels[1];
      }),
      
      new DelayedGameEvent(100, () {
        Gui.fadeOutLevel = fadeLevels[2];
        
        Main.timeScale = 1.0;
        Main.player.inputEnabled = true;
        
        if(callback != null)
          callback();
      })
    ]);
  }
  
  @override
  void handleInput(List<InputCode> inputCodes) { /* TODO */ }
  
  // Editor functions
  
  @override
  String getType() => type;
  
  @override
  JsObject buildHtml(String prefix, bool readOnly, List<Function> callbacks, Function onInputChange, Function update) {
    List<String> fadeTypes = ["Normal to white", "White to normal", "Normal to black", "Black to normal"];
    List<JsObject> options = [];
    for(int curFadeType=0; curFadeType<fadeTypes.length; curFadeType++) {
      options.add(
        option({'value': curFadeType}, fadeTypes.elementAt(curFadeType))
      );
    }
    
    return table({}, tbody({}, [
      tr({},
        td({}, "Fade Type")
      ),
      tr({},
        td({},
          select({
            'id': '${prefix}_fade_type',
            'disabled': readOnly,
            'value': fadeType,
            'onChange': onInputChange
          }, options)
        )
      )
    ]));
  }
  
  static GameEvent buildGameEvent(String prefix) {
    FadeGameEvent fadeGameEvent = new FadeGameEvent(
        Editor.getSelectInputIntValue("#${prefix}_fade_type", 2)
      );
    
    return fadeGameEvent;
  }
  
  @override
  Map<String, Object> buildJson() {
    Map<String, Object> gameEventJson = {};
    
    gameEventJson["type"] = type;
    gameEventJson["fadeType"] = fadeType;
    
    return gameEventJson;
  }
}