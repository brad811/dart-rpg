library Battler;

class Battler {
  final int
    baseHealth,
    baseAttack;
  
  int
    health,
    attack;
  
  List<String> attacks;
  
  Battler(this.baseHealth, this.baseAttack, this.attacks) {
    health = baseHealth;
    attack = baseAttack;
  }
}