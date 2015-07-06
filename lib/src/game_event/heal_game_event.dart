library dart_rpg.heal_game_event;

import 'package:dart_rpg/src/character.dart';
import 'package:dart_rpg/src/main.dart';

import 'package:dart_rpg/src/game_event/game_event.dart';

class HealGameEvent extends GameEvent {
  Character character;
  int amount;
  
  HealGameEvent(this.character, this.amount, [Function callback]) : super(null, callback);
  
  void trigger() {
    this.character = Main.player;
    
    character.battler.curHealth += amount;
    
    if(character.battler.curHealth > character.battler.startingHealth)
      character.battler.curHealth = character.battler.startingHealth;
    
    character.battler.displayHealth = character.battler.curHealth;
    
    callback();
  }
}