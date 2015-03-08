library Battler;

import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';

class Battler {
  final BattlerType battlerType;
  
  int
    startingHealth = 0,
    startingPhysicalAttack = 0,
    startingMagicalAttack = 0,
    startingPhysicalDefense = 0,
    startingMagicalDefense = 0,
    startingSpeed = 0,
    
    curHealth = 0,
    curPhysicalAttack = 0,
    curMagicalAttack = 0,
    curPhysicalDefense = 0,
    curMagicalDefense = 0,
    curSpeed = 0,
    
    healthProficiency = 0,
    physicalAttackProficiency = 0,
    magicalAttackProficiency = 0,
    physicalDefenseProficiency = 0,
    magicalDefenseProficiency = 0,
    speedProficiency = 0,
    
    level = 1,
    experience = 0,
    experiencePayout = 0,
    
    displayHealth = 0,
    displayExperience = 0;
  
  List<Attack> attacks;
  List<String> attackNames = [];
  
  Battler(this.battlerType, int level, this.attacks) {
    startingHealth = battlerType.baseHealth;
    startingPhysicalAttack = battlerType.basePhysicalAttack;
    startingMagicalAttack = battlerType.baseMagicalAttack;
    startingPhysicalDefense = battlerType.basePhysicalDefense;
    startingMagicalDefense = battlerType.baseMagicalDefense;
    startingSpeed = battlerType.baseSpeed;
    
    while(this.level < level)
      levelUp();
    
    experience = curLevelExperience();
    
    experiencePayout = (
      level * battlerType.rarity * battlerType.baseStatsSum() / 10
    ).round();
    
    reset();
    
    for(Attack attack in attacks) {
      attackNames.add(attack.name);
    }
  }
  
  void reset() {
    curHealth = startingHealth;
    curPhysicalAttack = startingPhysicalAttack;
    curMagicalAttack = startingMagicalAttack;
    curPhysicalDefense = startingPhysicalDefense;
    curMagicalDefense = startingMagicalDefense;
    curSpeed = startingSpeed;
    
    displayHealth = startingHealth;
    displayExperience = experience;
  }
  
  int levelExperience(int level) {
    return math.pow(level, 3);
  }
  
  int curLevelExperience() {
    return levelExperience(level);
  }
  
  int nextLevelExperience() {
    return levelExperience(level + 1);
  }
  
  void levelUp() {
    level += 1;

    int healthChange = (battlerType.baseHealth + (math.min(healthProficiency, 25))/5).round();
    startingHealth += healthChange;
    curHealth += healthChange;
    displayHealth += healthChange;
    
    int physicalAttackChange = (battlerType.basePhysicalAttack + (math.min(physicalAttackProficiency, 25))/5).round();
    startingPhysicalAttack += physicalAttackChange;
    curPhysicalAttack += physicalAttackChange;

    int magicalAttackChange = (battlerType.baseMagicalAttack + (math.min(magicalAttackProficiency, 25))/5).round();
    startingMagicalAttack += magicalAttackChange;
    curMagicalAttack += magicalAttackChange;
    
    int physicalDefenseChange = (battlerType.basePhysicalDefense + (math.min(physicalDefenseProficiency, 25))/5).round();
    startingPhysicalDefense += physicalDefenseChange;
    curPhysicalDefense += physicalDefenseChange;
    
    int magicalDefenseChange = (battlerType.baseMagicalDefense + (math.min(magicalDefenseProficiency, 25))/5).round();
    startingMagicalDefense += magicalDefenseChange;
    curMagicalDefense += magicalDefenseChange;
    
    int speedChange = (battlerType.baseSpeed + (math.min(speedProficiency, 25))/5).round();
    startingSpeed += speedChange;
    curSpeed += speedChange;
    
    // TODO: update available attacks
    // If player and attacks are full, prompt for which move to keep
    // If not player, delete least recent move
  }
}