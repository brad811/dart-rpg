library dart_rpg.item_potion;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/item.dart';

class ItemPotion implements Item {
  final String name = "Potion";
  final int basePrice = 100;
  final String description = "This potion heals you by 20.";
  final int pictureId = 237;
  
  void use(Battler target) {
    target.curHealth += 20;
  }
}