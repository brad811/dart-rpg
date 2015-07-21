library dart_rpg.warp_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/interactable_interface.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class WarpGameEvent extends GameEvent {
  Character character;
  String oldMap, newMap;
  int x, y, layer, direction;
  
  WarpGameEvent(this.oldMap, this.character,
    this.newMap, this.x, this.y, this.layer, this.direction,
    [Function callback]) : super(null, callback);
  
  void trigger(InteractableInterface interactable) {
    // change the character's location
    character.map = newMap;
    character.mapX = x;
    character.mapY = y;
    character.layer = layer;
    character.direction = direction;
    
    // fix since x and y are only calculated in constructor
    character.x = character.mapX * character.motionAmount;
    character.y = character.mapY * character.motionAmount;
    
    callback();
  }
}