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
  
  Battler(this.battlerType, this.attacks) {
    // TODO: where is starting stuff determined? calculated?
    startingHealth = battlerType.baseHealth;
    startingPhysicalAttack = battlerType.basePhysicalAttack;
    startingMagicAttack = battlerType.baseMagicAttack;
    startingPhysicalDefense = battlerType.basePhysicalDefense;
    startingMagicDefence = battlerType.baseMagicDefence;
    startingSpeed = battlerType.baseSpeed;
    
    reset();
    
    for(Attack attack in attacks) {
      attackNames.add(attack.name);
    }
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
    startingHealth += battlerType.baseHealth + (math.min(healthProficiency, 25))/5;
    startingPhysicalAttack += battlerType.basePhysicalAttack + (math.min(physicalAttackProficiency, 25))/5;
    startingMagicAttack += battlerType.baseMagicAttack + (math.min(magicAttackProficiency, 25))/5;
    startingPhysicalDefense += battlerType.basePhysicalDefense + (math.min(physicalDefenseProficiency, 25))/5;
    startingMagicDefence += battlerType.baseMagicDefence + (math.min(magicDefenseProficiency, 25))/5;
    startingSpeed += battlerType.baseSpeed + (math.min(speedProficiency, 25))/5;
  }
}