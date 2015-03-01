library Battler;

import 'package:dart_rpg/src/attack.dart';

class Battler {
  final String name;
  
  // TODO: determine leveling up behavior
  
  final int
    baseHealth,
    baseAttack,
    baseSpeed;
  
  int
    spriteId,
    health,
    displayHealth,
    attack,
    speed,
    experience = 0,
    displayExperience,
    experiencePayout = 0,
    nextLevel = 30;
  
  List<Attack> attacks;
  List<String> attackNames = [];
  
  Battler(
      this.spriteId, this.name,
      this.baseHealth, this.baseAttack, this.baseSpeed,
      this.attacks, this.experiencePayout) {
    reset();
    
    for(Attack attack in attacks) {
      attackNames.add(attack.name);
    }
  }
  
  void reset() {
    health = baseHealth;
    displayHealth = baseHealth;
    attack = baseAttack;
    speed = baseSpeed;
    displayExperience = experience;
  }
}