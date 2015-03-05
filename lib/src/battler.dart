library Battler;

import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';

class Battler {
  final BattlerType battlerType;
  
  int
    startingHealth = 0,
    startingPhysicalAttack = 0,
    startingMagicAttack = 0,
    startingPhysicalDefense = 0,
    startingMagicDefense = 0,
    startingSpeed = 0,
    
    curHealth = 0,
    curPhysicalAttack = 0,
    curMagicAttack = 0,
    curPhysicalDefense = 0,
    curMagicDefense = 0,
    curSpeed = 0,
    
    healthProficiency = 0,
    physicalAttackProficiency = 0,
    magicAttackProficiency = 0,
    physicalDefenseProficiency = 0,
    magicDefenseProficiency = 0,
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
    startingMagicAttack = battlerType.baseMagicAttack;
    startingPhysicalDefense = battlerType.basePhysicalDefense;
    startingMagicDefense = battlerType.baseMagicDefense;
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
    
    // TODO: automatically determine levelled stats and available moves
    // based on level
  }
  
  void reset() {
    curHealth = startingHealth;
    curPhysicalAttack = startingPhysicalAttack;
    curMagicAttack = startingMagicAttack;
    curPhysicalDefense = startingPhysicalDefense;
    curMagicDefense = startingMagicDefense;
    curSpeed = startingSpeed;
    
    displayHealth = startingHealth;
    displayExperience = experience;
    print("Name: ${battlerType.name}, attack: ${curPhysicalAttack}");
  }
  
  int levelExperience(int level) {
    return math.pow(level, 2);
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

    int magicAttackChange = (battlerType.baseMagicAttack + (math.min(magicAttackProficiency, 25))/5).round();
    startingMagicAttack += magicAttackChange;
    curMagicAttack += magicAttackChange;
    
    int physicalDefenseChange = (battlerType.basePhysicalDefense + (math.min(physicalDefenseProficiency, 25))/5).round();
    startingPhysicalDefense += physicalDefenseChange;
    curPhysicalDefense += physicalDefenseChange;
    
    int magicDefenseChange = (battlerType.baseMagicDefense + (math.min(magicDefenseProficiency, 25))/5).round();
    startingMagicDefense += magicDefenseChange;
    curMagicDefense += magicDefenseChange;
    
    int speedChange = (battlerType.baseSpeed + (math.min(speedProficiency, 25))/5).round();
    startingSpeed += speedChange;
    curSpeed += speedChange;
  }
}