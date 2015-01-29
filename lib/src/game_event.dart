library GameEvent;

class GameEvent {
  var callback;
  
  GameEvent(this.callback);
  
  void trigger() {}
}