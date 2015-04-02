library dart_rpg.item_stack;

import 'package:dart_rpg/src/item.dart';

class ItemStack {
  Item item;
  int quantity;
  
  ItemStack(this.item, this.quantity);
}