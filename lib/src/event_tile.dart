library dart_rpg.event_tile;

import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/sprite.dart';
import 'package:dart_rpg/src/tile.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class EventTile extends Tile {
  String gameEventChain;
  bool runOnce = false, hasRun = false;
  
  EventTile(this.gameEventChain, this.runOnce, Sprite sprite, [bool layered]) : super(false, sprite, layered);
  
  void enter() {
    if((runOnce && !hasRun) || !runOnce) {
      List<GameEvent> gameEvents = World.gameEventChains[gameEventChain];
      
      Interactable.chainGameEvents(Main.player, gameEvents).trigger(Main.player);
      
      hasRun = true;
    }
  }
}