library dart_rpg.battler_type;

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
  
  final Map<int, List<Attack>> levelAttacks;
  
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
  
  List<Attack> getAttacksForLevel(int level) {
    List<Attack> attacks = [];
    
    for(int i=0; i<levelAttacks.keys.length; i++) {
      int curLevel = levelAttacks.keys.elementAt(i);
      
      if(curLevel > level)
        break;
      
      attacks.addAll(levelAttacks[curLevel]);
    }
    
    return attacks;
  }
}