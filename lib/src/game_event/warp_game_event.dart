library dart_rpg.warp_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable_interface.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class WarpGameEvent extends GameEvent {
  String characterLabel;
  String newMap;
  int x, y, layer, direction;
  
  WarpGameEvent(this.characterLabel,
    this.newMap, this.x, this.y, this.layer, this.direction,
    [Function callback]) : super(null, callback);
  
  void trigger(InteractableInterface interactable) {
    Character character;
    
    if(characterLabel == "____player") {
      character = Main.player;
    } else {
      character = World.characters[characterLabel];
    }
      
    character.warp(newMap, x, y, layer, direction);
    callback();
  }
}