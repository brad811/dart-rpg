library Battle;

import 'package:dart_rpg/src/animation_game_event.dart';
import 'package:dart_rpg/src/choice_game_event.dart';
import 'package:dart_rpg/src/game_event.dart';
import 'package:dart_rpg/src/gui.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';

class Battle implements InteractableInterface {
  GameEvent gameEvent;
  
  int
    curChoiceX = 0,
    curChoiceY = 0;
  
  ChoiceGameEvent main, fight, powers, bag, run;
  
  void start() {
    AnimationGameEvent exit = new AnimationGameEvent((callback) {
      Main.focusObject = Main.player;
      Gui.windows.removeRange(0, Gui.windows.length);
      Main.inBattle = false;
    });
    
    fight = new ChoiceGameEvent.custom(
      this,
      ["Fire Round Punch Fly", "Kick", "Throw", "Fire"],
      [[exit],[exit],[exit],[exit]],
      5, 14, 10, 2
    );
    fight.remove = false;
    
    main = new ChoiceGameEvent.custom(
      this,
      ["Fight", "Powers", "Bag", "Run"],
      [[fight], [fight], [fight], [fight]],
      15, 14, 5, 2
    );
    main.remove = false;
    
    Main.inBattle = true;
    main.trigger();
  }
  
  void tick() {
    
  }
}