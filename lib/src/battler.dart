library Battler;

import 'package:dart_rpg/src/attack.dart';

class Battler {
  int spriteId;
  
  final int
    baseHealth,
    baseAttack;
  
  int
    health,
    attack;
  
  List<Attack> attacks;
  List<String> attackNames = [];
  
  Battler(this.spriteId, this.baseHealth, this.baseAttack, this.attacks) {
    health = baseHealth;
    attack = baseAttack;
    
    for(Attack attack in attacks) {
      attackNames.add(attack.name);
    }
  }
  
  getAttacked(Attack attack) {
    health -= attack.power;
  }
}