library dart_rpg.game_event;

import 'package:dart_rpg/src/input_handler.dart';

class GameEvent implements InputHandler {
  Function function, callback;
  
  GameEvent([this.function, this.callback]);
  
  void trigger() {
    function(callback);
  }
  
  void handleKeys(List<int> keyCodes) {}
  
  void finish() {}
}