library dart_rpg.inventory;

import 'package:dart_rpg/src/item.dart';

class ItemStack {
  Item item;
  int quantity;
  
  ItemStack(this.item, this.quantity);
}

class Inventory {
  Map<String, ItemStack> itemStacks = new Map<String, ItemStack>();
  int money = 0;
  
  Inventory(List<ItemStack> itemStacks) {
    for(ItemStack itemStack in itemStacks) {
      this.addItem(itemStack.item, itemStack.quantity);
    }
  }
  
  Item getItem(String itemName) {
    return itemStacks[itemName].item;
  }
  
  Item removeItem(String itemName, [int quantity = 1]) {
    if(itemName == null || itemName.length == 0)
      return null;

    if(itemStacks.containsKey(itemName)) {
      itemStacks[itemName].quantity -= quantity;
      if(itemStacks[itemName].quantity <= 0) {
        itemStacks.remove(itemName);
      }
      
      return itemStacks[itemName].item;
    }
    
    // TODO: handle no more items left differently?
    return null;
  }
  
  void addItem(Item item, [int quantity = 1]) {
    if(item == null)
      return;
    
    if(itemStacks.containsKey(item.name)) {
      itemStacks[item.name].quantity += quantity;
    } else {
      itemStacks[item.name] = new ItemStack(item, quantity);
    }
  }
  
  int getQuantity(String itemName) {
    if(itemStacks.containsKey(itemName))
      return itemStacks[itemName].quantity;
    else
      return 0;
  }
  
  List<String> itemNames() {
    return itemStacks.keys.toList();
  }
}