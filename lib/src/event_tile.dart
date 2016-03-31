library dart_rpg.event_tile;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/interactable_tile.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class EventTile extends InteractableTile {
  String gameEventChain;
  bool runOnce = false, hasRun = false, runOnEnter = false, runOnInteract = false;
  
  EventTile(
    this.gameEventChain,
    this.runOnce, this.runOnEnter, this.runOnInteract,
    Sprite sprite, [bool layered]
  ) : super(false, sprite, null, layered);
  
  @override
  void enter(Character character) {
    if(runOnEnter) {
      trigger();
    }
  }

  @override
  void interact() {
    if(runOnInteract)
    trigger();
  }

  void trigger() {
    if((runOnce && !hasRun) || !runOnce) {
      List<GameEvent> gameEvents = World.gameEventChains[gameEventChain];
      
      Interactable.chainGameEvents(Main.player.character, gameEvents).trigger(Main.player.character);
      
      hasRun = true;
    }
  }
}