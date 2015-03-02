library BattlerType;

import 'package:dart_rpg/src/attack.dart';

class BattlerType {
  final String name;
  
  final int
    spriteId,
    baseHealth,
    basePhysicalAttack,
    baseMagicAttack,
    basePhysicalDefense,
    baseMagicDefence,
    baseSpeed;
  
  final Map<int, Attack> levelAttacks;
  
  BattlerType(
      this.spriteId, this.name,
      this.baseHealth, this.basePhysicalAttack, this.baseMagicAttack,
      this.basePhysicalDefense, this.baseMagicDefence, this.baseSpeed,
      this.levelAttacks);
}