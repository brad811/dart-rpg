library GameEvent;

import 'package:dart_rpg/src/input_handler.dart';

class GameEvent implements InputHandler {
  dynamic callback;
  
  GameEvent();
  
  void trigger() {}
  
  void handleKeys(List<int> keyCodes) {}
  
  void finish() {}
}