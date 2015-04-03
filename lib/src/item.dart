library dart_rpg.item;

abstract class Item {
  static final String name = "Item";
  int price = 100;
  
  void use();
}