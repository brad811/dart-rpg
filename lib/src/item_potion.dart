library dart_rpg.item_potion;

import 'package:dart_rpg/src/item.dart';

class ItemPotion implements Item {
  static final String name = "Item";
  int price = 100;
  
  void use() {
    // TODO: make it heal
  }
}