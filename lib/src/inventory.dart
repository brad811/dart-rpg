library dart_rpg.inventory;

import 'package:dart_rpg/src/item.dart';
import 'package:dart_rpg/src/item_stack.dart';

class Inventory {
  List<ItemStack> itemStacks = new List<ItemStack>();
  int money = 0;
  
  Item removeItem(Item item, [int quantity = 1]) {
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
    
    // TODO: handle no more items left differently?
    return null;
  }
  
  void addItem(Item item, [int quantity = 1]) {
    if(item == null)
      return;
    
    for(ItemStack itemStack in itemStacks) {
      if(itemStack.item.name == item.name) {
        itemStack.quantity += quantity;
        return;
      }
    }
    
    ItemStack newItemStack = new ItemStack(item, quantity);
    itemStacks.add(newItemStack);
  }
}