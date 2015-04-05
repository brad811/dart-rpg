library dart_rpg.item;

import 'package:dart_rpg/src/battler.dart';

abstract class Item {
  final String name = "Item";
  final int basePrice = 100;
  final String description = "This is an item!";
  final int pictureId = 237;
  
  void use(Battler target);
}