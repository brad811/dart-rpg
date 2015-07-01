library dart_rpg.delay_game_event;

import 'dart:async';

import 'package:dart_rpg/src/game_event/game_event.dart';

class DelayGameEvent extends GameEvent {
  int milliseconds;
  
  DelayGameEvent(this.milliseconds, [Function callback]) : super(null, callback);
  
  void trigger() {
    Future future = new Future.delayed(new Duration(milliseconds: milliseconds), () {});
    
    future.then(callback);
  }
}