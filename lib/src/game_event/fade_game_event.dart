library dart_rpg.fade_game_event;

import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/delayed_game_event.dart';

class FadeGameEvent extends GameEvent {
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
  
  FadeGameEvent(this.fadeType, [Function callback]) : super(null, callback);
  
  void trigger(InteractableInterface interactable) {
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
}