library AnimationGameEvent;

import 'package:dart_rpg/src/game_event.dart';

class AnimationGameEvent extends GameEvent {
  dynamic function;
  
  AnimationGameEvent(this.function) : super();
  
  void trigger() {
    function(callback);
  }
}