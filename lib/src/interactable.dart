library dart_rpg.interactable;

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/main.dart';

class Interactable {
  static GameEvent chainGameEvents(List<GameEvent> gameEvents) {
    if(gameEvents == null || gameEvents.length == 0)
      return null;
    
    // Set each event to call the next event and update the character's
     // attached game event so they can handle input
     for(int i=1; i<gameEvents.length; i++) {
       gameEvents[i-1].callback = () {
         //interactable.gameEvent = gameEvents[i];
         gameEvents[i].trigger();
       };
     }
     
     // The last event should return focus to the player
     // and re-attach the first event to the character
     gameEvents.last.callback = () {
       Main.focusObject = Main.player;
     };
     
     return gameEvents[0];
  }
}