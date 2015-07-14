library dart_rpg.game_event;

import 'package:dart_rpg/src/input_handler.dart';
import 'package:dart_rpg/src/interactable_interface.dart';

class GameEvent implements InputHandler {
  Function function, callback;
  
  GameEvent([this.function, this.callback]);
  
  void trigger(InteractableInterface interactable) {
    function(callback);
  }
  
  void handleKeys(List<int> keyCodes) {}
  
  void finish() {}
}