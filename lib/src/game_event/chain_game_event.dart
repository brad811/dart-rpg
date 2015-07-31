library dart_rpg.chain_game_event;

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class ChainGameEvent extends GameEvent {
  String gameEventChain = "";
  bool makeDefault = false;
  
  ChainGameEvent(this.gameEventChain, this.makeDefault, [Function callback]) : super(null, callback);
  
  void trigger(InteractableInterface interactable) {
    List<GameEvent> gameEvents = World.gameEventChains[gameEventChain];
    if(gameEvents != null && gameEvents.length > 0) {
      if(makeDefault) {
        interactable.gameEventChain = gameEventChain;
      }
      
      Main.focusObject = null;
      Interactable.chainGameEvents(interactable, gameEvents).trigger(interactable);
    } else {
      callback();
    }
  }
}