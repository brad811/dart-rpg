library dart_rpg.item_potion;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/game_event/text_game_event.dart';

class ItemPotion implements Item {
  final String name = "Potion";
  final int basePrice = 100;
  final String description = "This potion heals you by 20. It's a pretty good deal. You should try it out. Don't hurt yourself to do that, though.";
  final int pictureId = 237;
  
  static final int healAmount = 20;
  
  TextGameEvent use(Battler target) {
    int healthBefore = target.curHealth;
    target.curHealth += 20;
    if(target.curHealth > target.startingHealth)
      target.curHealth = target.startingHealth;
    
    return new TextGameEvent(240, "${target.name} was healed by ${target.curHealth - healthBefore}!");
  }
}