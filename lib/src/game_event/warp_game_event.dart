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
    character.warp(newMap, x, y, layer, direction);
    callback();
  }
}