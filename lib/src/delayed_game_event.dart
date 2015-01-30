library DelayedGameEvent;

import 'dart:async';

class DelayedGameEvent {
  final Function function;
  final int delay;
  
  DelayedGameEvent(this.delay, this.function);
  
  static void executeDelayedEvents(List<DelayedGameEvent> events) {
    Future future = new Future.delayed(const Duration(milliseconds: 0), () {});
    for(DelayedGameEvent event in events) {
      future = addDelayed(future, event.delay, event.function);
    }
  }
  
  static Future addDelayed(Future future, int delay, Function function) {
    return future.then( (value) {
      return new Future.delayed(new Duration(milliseconds: delay), () {
        function();
      });
    });
  }
}