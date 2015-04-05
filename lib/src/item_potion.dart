library dart_rpg.item_potion;

import 'package:dart_rpg/src/battler.dart';
import 'package:dart_rpg/src/item.dart';

class ItemPotion implements Item {
  final String name = "Potion";
  int price = 100;
  
  void use(Battler target) {
    target.curHealth += 20;
  }
}