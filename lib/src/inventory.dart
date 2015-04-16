library dart_rpg.inventory;

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/item_stack.dart';

class Inventory {
  List<ItemStack> itemStacks = new List<ItemStack>();
  
  Item removeItem(Item item) {
    if(item == null)
      return null;
    
    for(ItemStack itemStack in itemStacks) {
      if(itemStack.item.name == item.name) {
        itemStack.quantity -= 1;
        
        if(itemStack.quantity == 0) {
          itemStacks.remove(itemStack);
        }
        
        return item;
      }
    }
    
    return null;
  }
}