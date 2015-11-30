library dart_rpg.attack;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/main.dart';
import 'package:dart_rpg/src/world.dart';

import 'package:dart_rpg/src/game_event/text_game_event.dart';

class Attack {
  final String name;
  final int power;
  final String type;
  
  static final int
    CATEGORY_PHYSICAL = 0,
    CATEGORY_MAGICAL = 1;
  
  final int category;
  
  TextGameEvent textGameEvent;
  
  // TODO: add optional argument for attack behavior
  // to handle things other than just dealing damage
  Attack(this.name, this.category, this.type, this.power);
  
  void use(Battler attacker, Battler defender, bool enemy, Function callback) {
    String text;
    if(enemy) {
      text = "Enemy ${attacker.battlerType.name} attacked ${defender.battlerType.name} with ${this.name}!";
    } else {
      text = "${attacker.battlerType.name} attacked enemy ${defender.battlerType.name} with ${this.name}!";
    }
    
    textGameEvent = new TextGameEvent(240, text, () {
      defender.curHealth -= calculateDamage(attacker, defender);
      callback();
    });
    textGameEvent.trigger(Main.player.character);
  }
  
  int calculateDamage(Battler attacker, Battler defender) {
    double damage,
      effectiveness = World.types[this.type].getEffectiveness(defender.battlerType.type);
    
    if(category == CATEGORY_PHYSICAL) {
      damage =
        (attacker.curPhysicalAttack / defender.curPhysicalDefense) * power * effectiveness;
    } else {
      damage =
        (attacker.curMagicalAttack / defender.curMagicalDefense) * power * effectiveness;
    }
    
    return damage.round();
  }
}