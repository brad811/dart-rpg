library dart_rpg.item;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/interactable.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class Item {
  final int pictureId;
  final String name;
  final int basePrice;
  final String description;
  
  final String gameEventChain;
  
  Item(
    this.pictureId,
    this.name,
    this.basePrice,
    this.description,
    this.gameEventChain
  );
  
  GameEvent use(Battler target, GameEvent callback) {
    if(gameEventChain == null || World.gameEventChains[gameEventChain] == null) {
      return new TextGameEvent(240, "The item had no effect!");
    } else {
      List<GameEvent> gameEvents = [];
      gameEvents.addAll(World.gameEventChains[gameEventChain]);
      gameEvents.add(callback);
      
      return Interactable.chainGameEvents(Main.player.getCurCharacter(), gameEvents);
    }
  }
}