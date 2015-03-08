library Attack;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/text_game_event.dart';

class Attack {
  final String name;
  final int power;
  
  // TODO: add attack types (fire, water, electric, etc.)
  // TODO: add physical vs magic
  
  TextGameEvent textGameEvent;
  
  // TODO: add optional argument for attack behavior
  // to handle things other than just dealing damage
  Attack(this.name, this.power);
  
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
    double damage =
        (attacker.curPhysicalAttack / defender.curPhysicalDefense) * power;
    
    return damage.round();
  }
}