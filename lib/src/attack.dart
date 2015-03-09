library Attack;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/text_game_event.dart';

class Attack {
  final String name;
  final int power;
  
  static final int
    CATEGORY_PHYSICAL = 0,
    CATEGORY_MAGICAL = 1;
  
  final int category;
  
  // TODO: add attack types (fire, water, electric, etc.)
  
  TextGameEvent textGameEvent;
  
  // TODO: add optional argument for attack behavior
  // to handle things other than just dealing damage
  Attack(this.name, this.category, this.power);
  
  void use(Battler attacker, Battler defender, bool enemy, Function callback) {
    String text = "${attacker.battlerType.name} attacked ${defender.battlerType.name} with ${this.name}!";
    if(enemy) {
      text = "Enemy ${text}";
    }
    textGameEvent = new TextGameEvent(240, text, () {
      defender.curHealth -= calculateDamage(attacker, defender);
      callback();
    });
    textGameEvent.trigger();
  }
  
  int calculateDamage(Battler attacker, Battler defender) {
    double damage;
    if(category == CATEGORY_PHYSICAL) {
      damage =
        (attacker.curPhysicalAttack / defender.curPhysicalDefense) * power;
    } else {
      damage =
        (attacker.curMagicalAttack / defender.curMagicalDefense) * power;
    }
    
    return damage.round();
  }
}