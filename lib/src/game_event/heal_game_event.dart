library dart_rpg.heal_game_event;

import 'package:dart_rpg/src/character.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class HealGameEvent extends GameEvent {
  Character character;
  int amount;
  
  HealGameEvent(this.character, this.amount, [Function callback]) : super(null, callback);
  
  void trigger() {
    character.battler.curHealth += amount;
  }
}