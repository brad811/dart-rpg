library BattlerType;

import 'package:dart_rpg/src/attack.dart';

class BattlerType {
  final String name;
  
  final int
    spriteId,
    
    baseHealth,
    basePhysicalAttack,
    baseMagicalAttack,
    basePhysicalDefense,
    baseMagicalDefense,
    baseSpeed;
  
  final double
    rarity;
  
  final Map<int, Attack> levelAttacks;
  
  BattlerType(
      this.spriteId, this.name,
      this.baseHealth, this.basePhysicalAttack, this.baseMagicalAttack,
      this.basePhysicalDefense, this.baseMagicalDefense, this.baseSpeed,
      this.levelAttacks,
      this.rarity);
  
  int baseStatsSum() {
    return
      baseHealth +
      basePhysicalAttack +
      baseMagicalAttack +
      basePhysicalDefense +
      baseMagicalDefense +
      baseSpeed;
  }
}