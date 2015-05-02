library dart_rpg.inventory;

import 'package:dart_rpg/src/item.dart';

class Inventory {
  Map<Item, int> itemQuantities = new Map<Item, int>();
  int money = 0;
  
  Item removeItem(Item item, [int quantity = 1]) {
    if(item == null)
      return null;

    if(itemQuantities.containsKey(item)) {
      itemQuantities[item] -= quantity;
      if(itemQuantities[item] <= 0) {
        itemQuantities.remove(item);
      }
      
      return item;
    }
    
    // TODO: handle no more items left differently?
    return null;
  }
  
  void addItem(Item item, [int quantity = 1]) {
    if(item == null)
      return;
    
    if(itemQuantities.containsKey(item)) {
      itemQuantities[item] += quantity;
    } else {
      itemQuantities[item] = quantity;
    }
  }
}