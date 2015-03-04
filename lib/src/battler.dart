library Battler;

import 'dart:math' as math;

import 'package:dart_rpg/src/attack.dart';
import 'package:dart_rpg/src/battler_type.dart';

class Battler {
  final BattlerType battlerType;
  
  int
    startingHealth,
    startingPhysicalAttack,
    startingMagicAttack,
    startingPhysicalDefense,
    startingMagicDefence,
    startingSpeed,
    
    curHealth,
    curPhysicalAttack,
    curMagicAttack,
    curPhysicalDefense,
    curMagicDefence,
    curSpeed,
    
    healthProficiency = 0,
    physicalAttackProficiency = 0,
    magicAttackProficiency = 0,
    physicalDefenseProficiency = 0,
    magicDefenseProficiency = 0,
    speedProficiency = 0,
    
    level = 1,
    experience = 0,
    experiencePayout = 0,
    
    displayHealth,
    displayExperience;
  
  List<Attack> attacks;
  List<String> attackNames = [];
  
  Battler(this.battlerType, int level, this.attacks) {
    startingHealth = battlerType.baseHealth;
    startingPhysicalAttack = battlerType.basePhysicalAttack;
    startingMagicAttack = battlerType.baseMagicAttack;
    startingPhysicalDefense = battlerType.basePhysicalDefense;
    startingMagicDefence = battlerType.baseMagicDefence;
    startingSpeed = battlerType.baseSpeed;
    
    while(this.level < level)
      levelUp();
    
    experience = math.pow(level, 3);
    
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
    curMagicDefence = startingMagicDefence;
    curSpeed = startingSpeed;
    
    displayHealth = startingHealth;
    displayExperience = experience;
  }
  
  void levelUp() {
    level += 1;
    
    startingHealth += (battlerType.baseHealth + (math.min(healthProficiency, 25))/5).round();
    startingPhysicalAttack += (battlerType.basePhysicalAttack + (math.min(physicalAttackProficiency, 25))/5).round();
    startingMagicAttack += (battlerType.baseMagicAttack + (math.min(magicAttackProficiency, 25))/5).round();
    startingPhysicalDefense += (battlerType.basePhysicalDefense + (math.min(physicalDefenseProficiency, 25))/5).round();
    startingMagicDefence += (battlerType.baseMagicDefence + (math.min(magicDefenseProficiency, 25))/5).round();
    startingSpeed += (battlerType.baseSpeed + (math.min(speedProficiency, 25))/5).round();
  }
}